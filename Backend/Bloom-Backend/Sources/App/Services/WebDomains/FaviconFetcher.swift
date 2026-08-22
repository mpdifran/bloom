//
//  FaviconFetcher.swift
//  Bloom-Backend
//

import Foundation
import Vapor
import Fluent
import BloomModel
import AsyncHTTPClient
import NIOCore

/// Fetches and stores the site icon shown beside a citation.
///
/// Served from Bloom's own storage rather than pointed at a third-party favicon service: rendering
/// a citation would otherwise tell that service which sites a user is reading about, which is at
/// odds with what the app promises about health data.
///
/// Everything here is best-effort. A site with no icon, a slow server, or a 404 all produce the
/// same outcome - no favicon - and the client falls back to a lettered circle.
struct FaviconFetcher: Sendable {

  let httpClient: HTTPClient
  let imageStorage: any ImageStorage
  let logger: Logger

  /// Well past what a favicon needs, and small enough that a hostile response can't be used to
  /// exhaust memory.
  private static let maxBytes = 512 * 1024
  private static let timeout = TimeAmount.seconds(5)

  /// Icons are refreshed occasionally - sites rebrand - but not on any hot path.
  private static let refreshInterval: TimeInterval = 60 * 60 * 24 * 30
}

extension FaviconFetcher {

  /// Fetches the icon for a host and records where it was stored.
  ///
  /// Safe to call for a host that already has one: it returns early unless the stored icon has
  /// aged out.
  func fetchIfNeeded(host: String, db: any Database) async {
    do {
      guard let record = try await WebDomainReputation.find(host, on: db) else { return }

      if let fetchedAt = record.faviconFetchedAt,
         Date().timeIntervalSince(fetchedAt) < Self.refreshInterval {
        return
      }

      guard let image = await fetchIcon(host: host) else {
        // Record the attempt regardless, so a site with no icon isn't retried on every citation.
        record.faviconFetchedAt = Date()
        try await record.save(on: db)
        return
      }

      let metadata = try await imageStorage.store(image: image, path: .favicons)
      record.faviconURL = imageStorage.generatePublicURL(
        fileName: metadata.filename,
        path: .favicons
      )?.absoluteString
      record.faviconFetchedAt = Date()
      try await record.save(on: db)

      logger.debug("Stored favicon for \(host)")
    } catch {
      logger.warning("Favicon fetch failed for \(host): \(error)")
    }
  }

  /// Tries the conventional locations, largest-and-nicest first.
  private func fetchIcon(host: String) async -> ImageFile? {
    let candidates = [
      "https://\(host)/apple-touch-icon.png",
      "https://\(host)/apple-touch-icon-precomposed.png",
      "https://\(host)/favicon.ico",
    ]

    for candidate in candidates {
      if let image = await download(candidate) {
        return image
      }
    }
    return nil
  }

  private func download(_ urlString: String) async -> ImageFile? {
    do {
      var request = HTTPClientRequest(url: urlString)
      request.method = .GET
      // Some CDNs serve nothing useful without one.
      request.headers.add(name: "User-Agent", value: "BloomBot/1.0 (+https://bloomhealth.app)")

      let response = try await httpClient.execute(request, timeout: Self.timeout)
      guard response.status == .ok else { return nil }

      let body = try await response.body.collect(upTo: Self.maxBytes)
      guard body.readableBytes > 0, let data = body.getData(at: 0, length: body.readableBytes) else {
        return nil
      }

      let ext = urlString.hasSuffix(".ico") ? "ico" : "png"
      return ImageFile(data: data, fileExtension: ext)
    } catch {
      // Expected constantly - sites without an apple-touch-icon 404 on the first two candidates -
      // so this is deliberately quiet.
      return nil
    }
  }
}
