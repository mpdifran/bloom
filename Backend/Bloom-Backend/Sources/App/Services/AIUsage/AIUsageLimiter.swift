//
//  AIUsageLimiter.swift
//  Bloom-Backend
//
//  Created by Claude on 2026-08-05.
//

import Vapor
import Redis
import BloomModel
import OpenAIKit

/// Per-user AI spend budget (rolling daily + monthly caps), backed by Redis.
///
/// Counters are denominated in micro-dollars (µ$) rather than tokens, because the model map mixes
/// tiers whose rates differ by up to 100x — a token cap would buy wildly different amounts of
/// spend depending on which endpoint the user happened to hit.
///
/// `checkBudget` is called BEFORE dispatching an OpenAI request and rejects the request with
/// `429 Too Many Requests` once the user has crossed either cap. `record` is called AFTER a
/// request completes to add its real cost to the user's counters.
///
/// Fails open: any Redis error is logged and treated as "under budget", so a Redis outage never
/// blocks legitimate users — it only pauses abuse protection until Redis recovers.
struct AIUsageLimiter: Sendable {
  let redis: RedisClient
  let logger: Logger
  /// Daily cap in µ$.
  let dailyLimit: Int
  /// Monthly cap in µ$.
  let monthlyLimit: Int

  /// Throws `Abort(.tooManyRequests)` when the user is already at/over the daily or monthly cap.
  /// Call this before starting any OpenAI request.
  func checkBudget(for userID: UserIdentifier) async throws {
    do {
      let keys = keys(for: userID)

      let dayCost = try await redis.get(keys.day, as: Int.self).get() ?? 0
      if dayCost >= dailyLimit {
        throw Abort(.tooManyRequests, reason: "You've reached today's AI usage limit. Please try again tomorrow.")
      }

      let monthCost = try await redis.get(keys.month, as: Int.self).get() ?? 0
      if monthCost >= monthlyLimit {
        throw Abort(.tooManyRequests, reason: "You've reached this month's AI usage limit.")
      }
    } catch let abort as AbortError {
      throw abort
    } catch {
      logger.warning("AIUsageLimiter.checkBudget failed for \(userID.value); allowing request (fail-open): \(error)")
    }
  }

  /// Prices the completion against `model` and adds it to the user's counters (fail-open).
  /// Call this after an OpenAI request completes.
  func record(
    model: ModelID,
    inputTokens: Int,
    outputTokens: Int,
    for userID: UserIdentifier
  ) async {
    let cost = ModelPricing.cost(model: model, inputTokens: inputTokens, outputTokens: outputTokens)
    await record(microdollars: cost, for: userID)
  }

  /// Adds `microdollars` to the user's daily and monthly counters (fail-open).
  func record(microdollars: Int, for userID: UserIdentifier) async {
    guard microdollars > 0 else { return }
    do {
      let keys = keys(for: userID)

      let dayTotal = try await redis.increment(keys.day, by: microdollars).get()
      if dayTotal == microdollars {
        // First write in this window — set the TTL (a little over 24h to absorb clock skew).
        _ = try await redis.expire(keys.day, after: .seconds(60 * 60 * 26)).get()
      }

      let monthTotal = try await redis.increment(keys.month, by: microdollars).get()
      if monthTotal == microdollars {
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
      day: RedisKey("aiusage:cost:day:\(userID.value):\(year)\(month)\(day)"),
      month: RedisKey("aiusage:cost:month:\(userID.value):\(year)\(month)")
    )
  }
}
