//
//  WebDomainBlocklist.swift
//  Bloom-Backend
//

import Foundation
import Vapor
import Fluent
import Redis

/// The short blocklist sent to OpenAI with each search request.
///
/// This is the *request-time* gate, and it is an optimization rather than a safety control: it
/// stops the model reading junk, which saves tokens and improves answers. The authoritative gate is
/// the one in `WebDomainService`, which runs when a citation is about to be shown and is bounded by
/// nothing.
///
/// OpenAI caps `blocked_domains` at 100 entries, so this carries the domains that actually recur.
/// Everything past the cap is still caught at emit time, which is why the cap does not matter.
///
/// Cached in Redis as a single small key. Note the full blocklist is deliberately *not* held there
/// - it runs to six figures, and that instance is 25 MB with `noeviction`, where a set that size
/// would start failing writes and take chat streaming state down with it. A hundred domains is a
/// few kilobytes.
struct WebDomainBlocklist: Sendable {

  let logger: Logger

  static let maxDomains = 100
  static let cacheKey = RedisKey("websearch:blocklist:top100")
  /// Long enough that a chat request almost never pays to rebuild it, short enough that a newly
  /// blocked domain reaches the filter within the hour.
  static let cacheTTL = 900
}

extension WebDomainBlocklist {

  /// The domains worth spending the request-time filter on, most-cited first.
  func topBlocked(db: any Database, redis: (any RedisClient)?) async -> [String] {
    if let cached = await cachedDomains(redis: redis) {
      return cached
    }

    let domains = await rebuild(db: db, redis: redis)
    return domains
  }

  /// Recomputes the list from the database and refreshes the cache.
  @discardableResult
  func rebuild(db: any Database, redis: (any RedisClient)?) async -> [String] {
    do {
      let records = try await WebDomainReputation.query(on: db)
        .filter(\.$verdict == .blocked)
        // Frequency is the only sensible ranking: a domain nobody encounters costs nothing to
        // leave off, however unpleasant it is.
        .sort(\.$observationCount, .descending)
        .limit(Self.maxDomains)
        .all()

      let domains = records.compactMap(\.id)
      await cache(domains, redis: redis)
      return domains
    } catch {
      // Fail open. The emit-time filter is what actually protects anyone, and a database blip
      // should not stop the assistant answering.
      logger.warning("Could not rebuild the request-time blocklist: \(error)")
      return []
    }
  }

  private func cachedDomains(redis: (any RedisClient)?) async -> [String]? {
    guard let redis else { return nil }
    do {
      guard let raw = try await redis.get(Self.cacheKey, as: String.self).get(), let data = raw.data(using: .utf8) else {
        return nil
      }
      return try JSONDecoder().decode([String].self, from: data)
    } catch {
      return nil
    }
  }

  private func cache(_ domains: [String], redis: (any RedisClient)?) async {
    guard let redis, let data = try? JSONEncoder().encode(domains),
          let raw = String(data: data, encoding: .utf8) else { return }

    _ = try? await redis.setex(Self.cacheKey, to: raw, expirationInSeconds: Self.cacheTTL).get()
  }
}
