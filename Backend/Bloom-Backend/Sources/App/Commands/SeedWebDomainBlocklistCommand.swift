//
//  SeedWebDomainBlocklistCommand.swift
//  Bloom-Backend
//

import Foundation
import Vapor
import Fluent
import AsyncHTTPClient
import NIOCore
import SQLKit

/// Imports a public blocklist so web search does not launch from a cold start.
///
/// Without this, a domain can only be blocked *after* someone has already been shown it once -
/// classification needs to have seen a host to judge it. Seeding from a maintained list means the
/// bulk of the adult and malware web is refused from the first request, and the classifier only has
/// to handle the tail.
///
/// The list is large - six figures - which is fine. Each row is a couple of hundred bytes, so a
/// full import is roughly 20 MB against a 10 GB database, and lookups are primary-key hits.
/// Deliberately *not* held in Redis: that instance is 25 MB with `noeviction`, so a set this size
/// would consume a third of it and start failing writes, taking chat streaming state with it.
///
///     swift run App seed-web-blocklist
///     swift run App seed-web-blocklist --source https://example.com/hosts.txt
struct SeedWebDomainBlocklistCommand: AsyncCommand {

  /// StevenBlack's porn-only host list: widely used, actively maintained, and in the simple
  /// `0.0.0.0 host` format.
  static let defaultSource =
    "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn-only/hosts"

  struct Signature: CommandSignature {
    @Option(name: "source", help: "URL of a hosts-format blocklist. Defaults to StevenBlack porn-only.")
    var source: String?

    @Option(name: "limit", help: "Stop after this many domains. Useful for a smoke test.")
    var limit: Int?
  }

  var help: String {
    "Imports a public host blocklist into web_domain_reputations"
  }

  func run(using context: CommandContext, signature: Signature) async throws {
    let app = context.application
    let source = signature.source ?? Self.defaultSource

    context.console.info("Fetching blocklist from \(source)")

    var request = HTTPClientRequest(url: source)
    request.method = .GET
    let response = try await app.http.client.shared.execute(request, timeout: .seconds(120))

    guard response.status == .ok else {
      throw Abort(.badRequest, reason: "Blocklist fetch failed with status \(response.status)")
    }

    // These lists run to a few megabytes of text.
    let body = try await response.body.collect(upTo: 32 * 1024 * 1024)
    guard let text = body.getString(at: 0, length: body.readableBytes) else {
      throw Abort(.internalServerError, reason: "Blocklist was not readable as text")
    }

    let hosts = Self.parseHosts(from: text, limit: signature.limit)
    context.console.info("Parsed \(hosts.count) domains")

    guard let sql = app.db as? any SQLDatabase else {
      throw Abort(.internalServerError, reason: "Seeding requires a SQL database")
    }

    var inserted = 0
    // Batched, because a row-at-a-time insert of six figures takes long enough to look hung.
    for batch in hosts.chunked(into: 1_000) {
      let values = batch
        .map { "('\($0.replacingOccurrences(of: "'", with: "''"))', 'blocked', 'seed', false, 0, now(), now())" }
        .joined(separator: ",")

      // A domain we have already judged - especially by hand - outranks the list.
      try await sql.raw("""
        INSERT INTO web_domain_reputations
          (id, verdict, source, manual_override, observation_count, first_seen_at, last_seen_at)
        VALUES \(unsafeRaw: values)
        ON CONFLICT (id) DO NOTHING
        """).run()

      inserted += batch.count
      if inserted.isMultiple(of: 10_000) {
        context.console.info("  \(inserted)/\(hosts.count)")
      }
    }

    context.console.success("Seeded \(inserted) blocked domains")
  }

  /// Reads the `0.0.0.0 example.com` hosts format, ignoring comments and loopback entries.
  static func parseHosts(from text: String, limit: Int?) -> [String] {
    var hosts = Set<String>()

    for line in text.split(separator: "\n") {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

      let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
      guard parts.count >= 2 else { continue }

      var host = String(parts[1]).lowercased()
      if host.hasPrefix("www.") { host = String(host.dropFirst(4)) }

      // The list's own scaffolding, not sites.
      guard host != "localhost", host != "localhost.localdomain", host != "0.0.0.0",
            host.contains("."), !WebDomainService.neverBlocked.contains(host) else { continue }

      hosts.insert(host)

      if let limit, hosts.count >= limit { break }
    }

    return Array(hosts)
  }
}
