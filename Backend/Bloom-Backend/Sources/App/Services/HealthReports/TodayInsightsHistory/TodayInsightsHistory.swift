//
//  TodayInsightsHistory.swift
//  Bloom-Backend
//
//  Created by Assistant on 2025-08-30.
//

import Foundation
import Vapor
import BloomModel
@preconcurrency import Redis

final actor TodayInsightsHistory {

  init(redis: RedisClient, logger: Logger) {
    self.redis = redis
    self.logger = logger
  }

  private let redis: RedisClient
  private let logger: Logger
  
  // In-memory fallback storage
  private var fallbackLastResponseIDs: [UserIdentifier: String] = [:]
  
  // Redis health tracking
  private var redisIsHealthy = true
  private var lastRedisFailure: Date?
  private let redisRetryInterval: TimeInterval = 30 // Retry Redis after 30 seconds
}

extension TodayInsightsHistory {
  
  // MARK: - Redis Health Management
  
  private func markRedisUnhealthy(_ error: Error) {
    redisIsHealthy = false
    lastRedisFailure = Date()
    logger.error("Redis operation failed, falling back to in-memory storage: \(error)")
  }
  
  private func shouldTryRedis() -> Bool {
    guard !redisIsHealthy else { return true }
    guard let lastFailure = lastRedisFailure else { return true }
    
    // Retry Redis after the retry interval
    return Date().timeIntervalSince(lastFailure) >= redisRetryInterval
  }
  
  private func testAndRestoreRedisConnection() async -> Bool {
    guard !redisIsHealthy else { return true }
    guard shouldTryRedis() else { return false }
    
    do {
      // Test Redis connection with a simple ping
      _ = try await redis.ping().get()
      
      // If ping succeeds, sync data before marking healthy
      logger.info("Redis ping successful, syncing data before restoring connection...")
      await syncFallbackDataToRedis()
      
      // Mark as healthy only after sync completes
      redisIsHealthy = true
      lastRedisFailure = nil
      logger.info("Redis connection restored and synced")
      
      return true
    } catch {
      markRedisUnhealthy(error)
      return false
    }
  }
  
  private func markRedisHealthy() {
    if !redisIsHealthy {
      redisIsHealthy = true
      lastRedisFailure = nil
    }
  }
  
  private func syncFallbackDataToRedis() async {
    logger.info("Syncing fallback data to Redis after connection restoration")
    
    // Sync last response IDs
    for (userID, responseID) in fallbackLastResponseIDs {
      do {
        let key = RedisKey.lastResponseID(userID: userID)
        _ = try await redis.set(key, to: responseID).get()
        _ = try await redis.expire(key, after: .seconds(2592000)).get() // 30 days
      } catch {
        logger.error("Failed to sync last response ID for user \(userID): \(error)")
      }
    }
    
    logger.info("Completed syncing fallback data to Redis")
  }
}

extension TodayInsightsHistory {
  
  // MARK: - Public Interface

  func storeLastResponseID(
    _ responseID: String,
    for userID: UserIdentifier
  ) async throws {
    // Always store in fallback as a mirror
    fallbackLastResponseIDs[userID] = responseID
    
    // Try to store in Redis if it's healthy  
    if shouldTryRedis() {
      do {
        let key = RedisKey.lastResponseID(userID: userID)
        _ = try await redis.set(key, to: responseID).get()
        _ = try await redis.expire(key, after: .seconds(2592000)).get() // 30 days
        markRedisHealthy()
      } catch {
        markRedisUnhealthy(error)
      }
    }
  }
  
  func getLastResponseID(
    for userID: UserIdentifier
  ) async throws -> String? {
    // Test and restore Redis connection if needed, then try Redis
    if await testAndRestoreRedisConnection() {
      do {
        let key = RedisKey.lastResponseID(userID: userID)
        let result = try await redis.get(key).get().string
        markRedisHealthy()
        return result
      } catch {
        markRedisUnhealthy(error)
      }
    }
    
    // Fall back to in-memory storage
    return fallbackLastResponseIDs[userID]
  }
  
  func clearLastResponseID(
    for userID: UserIdentifier
  ) async throws {
    // Always clear from fallback
    fallbackLastResponseIDs.removeValue(forKey: userID)
    
    // Try to clear from Redis if it's healthy
    if shouldTryRedis() {
      do {
        let key = RedisKey.lastResponseID(userID: userID)
        _ = try await redis.delete(key).get()
        markRedisHealthy()
      } catch {
        markRedisUnhealthy(error)
      }
    }
  }
}

private extension RedisKey {

  static func lastResponseID(userID: UserIdentifier) -> RedisKey {
    RedisKey("today_insights_response_id:\(userID)")
  }
}