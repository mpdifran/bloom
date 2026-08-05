//
//  Application+AIUsageLimiter.swift
//  Bloom-Backend
//
//  Created by Claude on 2026-08-05.
//

import Vapor

extension Application {

  private struct AIUsageLimiterKey: StorageKey {
    typealias Value = AIUsageLimiter
  }

  var aiUsageLimiter: AIUsageLimiter {
    if let limiter = storage[AIUsageLimiterKey.self] {
      return limiter
    }

    let limiter = AIUsageLimiter(
      redis: redis,
      logger: logger,
      dailyLimit: aiTokenDailyLimit,
      monthlyLimit: aiTokenMonthlyLimit
    )

    storage[AIUsageLimiterKey.self] = limiter
    return limiter
  }
}

extension Request {

  var aiUsageLimiter: AIUsageLimiter {
    application.aiUsageLimiter
  }
}
