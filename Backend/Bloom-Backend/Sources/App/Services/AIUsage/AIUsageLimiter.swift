//
//  AIUsageLimiter.swift
//  Bloom-Backend
//
//  Created by Claude on 2026-08-05.
//

import Vapor
import Redis
import BloomModel

/// Per-user AI token budget (rolling daily + monthly caps), backed by Redis.
///
/// `checkBudget` is called BEFORE dispatching an OpenAI request and rejects the request with
/// `429 Too Many Requests` once the user has crossed either cap. `record` is called AFTER a
/// request completes to add the real token usage to the user's counters.
///
/// Fails open: any Redis error is logged and treated as "under budget", so a Redis outage never
/// blocks legitimate users — it only pauses abuse protection until Redis recovers.
struct AIUsageLimiter: Sendable {
  let redis: RedisClient
  let logger: Logger
  let dailyLimit: Int
  let monthlyLimit: Int

  /// Throws `Abort(.tooManyRequests)` when the user is already at/over the daily or monthly cap.
  /// Call this before starting any OpenAI request.
  func checkBudget(for userID: UserIdentifier) async throws {
    do {
      let keys = keys(for: userID)

      let dayCount = try await redis.get(keys.day, as: Int.self).get() ?? 0
      if dayCount >= dailyLimit {
        throw Abort(.tooManyRequests, reason: "You've reached today's AI usage limit. Please try again tomorrow.")
      }

      let monthCount = try await redis.get(keys.month, as: Int.self).get() ?? 0
      if monthCount >= monthlyLimit {
        throw Abort(.tooManyRequests, reason: "You've reached this month's AI usage limit.")
      }
    } catch let abort as AbortError {
      throw abort
    } catch {
      logger.warning("AIUsageLimiter.checkBudget failed for \(userID.value); allowing request (fail-open): \(error)")
    }
  }

  /// Adds `tokens` to the user's daily and monthly counters (fail-open).
  /// Call this after an OpenAI request completes with its total token count.
  func record(tokens: Int, for userID: UserIdentifier) async {
    guard tokens > 0 else { return }
    do {
      let keys = keys(for: userID)

      let dayTotal = try await redis.increment(keys.day, by: tokens).get()
      if dayTotal == tokens {
        // First write in this window — set the TTL (a little over 24h to absorb clock skew).
        _ = try await redis.expire(keys.day, after: .seconds(60 * 60 * 26)).get()
      }

      let monthTotal = try await redis.increment(keys.month, by: tokens).get()
      if monthTotal == tokens {
        _ = try await redis.expire(keys.month, after: .seconds(60 * 60 * 24 * 32)).get()
      }
    } catch {
      logger.warning("AIUsageLimiter.record failed for \(userID.value): \(error)")
    }
  }

  private func keys(for userID: UserIdentifier) -> (day: RedisKey, month: RedisKey) {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
    let components = calendar.dateComponents([.year, .month, .day], from: Date())
    let year = components.year ?? 0
    let month = String(format: "%02d", components.month ?? 0)
    let day = String(format: "%02d", components.day ?? 0)

    return (
      day: RedisKey("aiusage:tokens:day:\(userID.value):\(year)\(month)\(day)"),
      month: RedisKey("aiusage:tokens:month:\(userID.value):\(year)\(month)")
    )
  }
}
