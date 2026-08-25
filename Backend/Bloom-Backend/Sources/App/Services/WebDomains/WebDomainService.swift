//
//  WebDomainService.swift
//  Bloom-Backend
//

import Foundation
import Vapor
import Fluent
import BloomModel
import OpenAIKit

/// Decides whether a cited page may be shown, and builds what the client renders.
///
/// There are two gates, and separating them is what makes the 100-domain cap on OpenAI's filter
/// stop mattering:
///
/// - **Request time**, via `filters.blocked_domains`, capped at 100 entries. Stops the model
///   *reading* junk, which saves tokens and improves answers. An optimization, and it fails open on
///   everything past the cap.
/// - **Emit time**, here, unbounded. Stops a bad URL ever reaching a user. This is the control that
///   actually protects anyone.
struct WebDomainService: Sendable {

  let logger: Logger

  /// Domains that must never be blocked, whatever a classifier later decides.
  ///
  /// A circuit breaker: one bad verdict on a site like these breaks a whole category of ordinary
  /// question - restaurants, general lookups - and would be hard to spot from the outside.
  static let neverBlocked: Set<String> = [
    "wikipedia.org", "nih.gov", "pubmed.ncbi.nlm.nih.gov", "ncbi.nlm.nih.gov",
    "cdc.gov", "who.int", "mayoclinic.org", "clevelandclinic.org", "cochrane.org",
    "health.harvard.edu", "examine.com", "hopkinsmedicine.org", "nhs.uk",
    "yelp.com", "tripadvisor.com", "tripadvisor.ca", "opentable.com", "google.com",
    "reddit.com", "apple.com", "nytimes.com", "bbc.co.uk", "reuters.com", "apnews.com",
  ]

  /// Top-level domains that are either overwhelmingly adult or overwhelmingly abused.
  ///
  /// Deterministic, free, and applied before anything else - the long tail of adult domains is
  /// lexically self-describing, which is most of what a seed list misses.
  private static let blockedTLDs: Set<String> = [
    "xxx", "adult", "porn", "sex", "cam", "tube", "zip", "mov", "click", "top",
  ]

  private static let blockedHostFragments: [String] = [
    "porn", "xxx", "escort", "camgirl", "onlyfans", "hentai", "nsfw",
  ]
}

// MARK: - Normalization

extension WebDomainService {

  /// The key everything is stored under: lowercased host, `www.` stripped.
  static func normalizedHost(from url: URL) -> String? {
    guard let host = url.host()?.lowercased(), host.isNotEmpty else { return nil }
    return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
  }

  /// What to show on a chip. "tripadvisor.ca" reads as "Tripadvisor".
  ///
  /// Deliberately crude - a real display name comes from the classifier later. This only has to be
  /// better than showing a bare hostname.
  static func displayName(forHost host: String) -> String {
    let components = host.split(separator: ".")
    // Drop the TLD, and a country code sitting behind one (bbc.co.uk -> bbc).
    let meaningful = components.dropLast(components.count >= 3 && components.suffix(2).first?.count == 2 ? 2 : 1)
    guard let name = meaningful.last, name.isNotEmpty else { return host }
    return name.prefix(1).uppercased() + name.dropFirst()
  }
}

// MARK: - Gate B: may this citation be shown?

extension WebDomainService {

  /// Whether a URL is unacceptable on its face, before any database lookup.
  ///
  /// Runs first because it costs nothing and catches the cases a seed list is worst at.
  static func failsDeterministicChecks(_ url: URL) -> Bool {
    guard url.scheme?.lowercased() == "https" else { return true }
    guard let host = normalizedHost(from: url) else { return true }

    if neverBlocked.contains(host) { return false }

    if let tld = host.split(separator: ".").last, blockedTLDs.contains(String(tld)) {
      return true
    }

    if blockedHostFragments.contains(where: { host.contains($0) }) {
      return true
    }

    // A URL containing parentheses cannot be rendered as markdown and tends to indicate a
    // malformed citation. Cheaper to drop than to escape.
    if url.absoluteString.contains("(") || url.absoluteString.contains(")") {
      return true
    }

    return false
  }

  /// Whether a host is blocked according to what we have recorded.
  ///
  /// Looked up in Postgres rather than held as a Redis set. The seeded blocklist runs to six
  /// figures, and prod Redis is a 25 MB instance with `noeviction` - putting the list there would
  /// consume a third of it and start failing *writes*, taking chat streaming state down with it.
  /// A primary-key lookup is sub-millisecond and has none of that risk.
  func isBlocked(host: String, db: any Database) async -> Bool {
    guard !Self.neverBlocked.contains(host) else { return false }

    do {
      guard let record = try await WebDomainReputation.find(host, on: db) else {
        // Never seen. Shown, and recorded for classification - see `observe`.
        return false
      }
      return record.verdict == .blocked
    } catch {
      // Fail open. A database blip should not silently strip every citation from an answer, and
      // the deterministic checks above have already run.
      logger.warning("Domain lookup failed for \(host): \(error)")
      return false
    }
  }
}

// MARK: - Building what the client renders

extension WebDomainService {

  /// Turns the model's citations into the sources a client can render, dropping anything that
  /// should not be shown.
  ///
  /// - Returns: the surviving sources paired with the index of the citation each came from, so the
  ///   caller can still tell which message a source belongs to after drops and deduplication.
  func sourceRefs(
    from citations: [OpenAIKit.Response.Annotation.URLCitation],
    db: any Database
  ) async -> [(citationOffset: Int, ref: SocketMessage.SourceRef)] {
    var refs = [(citationOffset: Int, ref: SocketMessage.SourceRef)]()
    var seenHosts = Set<String>()

    for (offset, citation) in citations.enumerated() {
      guard !Self.failsDeterministicChecks(citation.url) else {
        logger.debug("Dropped citation \(citation.url.absoluteString): failed deterministic checks")
        continue
      }
      guard let host = Self.normalizedHost(from: citation.url) else { continue }
      guard await !isBlocked(host: host, db: db) else {
        logger.debug("Dropped citation \(citation.url.absoluteString): host is blocked")
        continue
      }
      // One chip per site. The model cites the same page for several claims and the repetition
      // reads as noise.
      guard seenHosts.insert(host).inserted else { continue }

      let record = try? await WebDomainReputation.find(host, on: db)

      refs.append(
        (offset, SocketMessage.SourceRef(
          id: "\(offset)-\(host)",
          url: citation.url.absoluteString,
          host: host,
          siteName: record?.siteName ?? Self.displayName(forHost: host),
          title: citation.title.truncated(to: 120),
          faviconURL: record?.faviconURL
        ))
      )

      // The same payload goes out over APNs when the socket is down, and that has a size ceiling.
      if refs.count >= 8 { break }
    }

    return refs
  }

  /// Records that a domain was cited, so it can be classified and have its favicon fetched.
  ///
  /// Detached from the response path by the caller - none of this should delay a chat message.
  func observe(hosts: [String], db: any Database) async {
    for host in Set(hosts) {
      do {
        if let existing = try await WebDomainReputation.find(host, on: db) {
          existing.observationCount += 1
          try await existing.save(on: db)
        } else {
          let record = WebDomainReputation(host: host, verdict: .pending, source: .observed)
          try await record.save(on: db)
        }
      } catch {
        logger.warning("Could not record domain observation for \(host): \(error)")
      }
    }
  }
}
