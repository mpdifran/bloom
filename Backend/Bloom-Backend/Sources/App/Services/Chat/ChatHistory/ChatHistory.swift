//
//  ChatHistory.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-05-21.
//

import Foundation
import Vapor
import BloomModel
@preconcurrency import Redis
import OpenAIKit

private extension Int {
  static let historyLimit: Int = 10
}

private struct CachedStreamingContent {
  let data: [Data]
  let timestamp: Date
  
  var isExpired: Bool {
    Date().timeIntervalSince(timestamp) > 3600 // 1 hour expiration
  }
}

final actor ChatHistory {

  init(redis: RedisClient, logger: Logger) {
    self.redis = redis
    self.logger = logger
  }

  private let redis: RedisClient
  private let logger: Logger
  private let encoder = JSONEncoder.bloomModel
  private let decoder = JSONDecoder.bloomModel
  
  // In-memory fallback storage
  private var fallbackLastResponseIDs: [UserIdentifier: String] = [:]
  private var fallbackFunctionCallIDs: [UserIdentifier: Set<String>] = [:]
  private var fallbackStreamingContent: [UserIdentifier: CachedStreamingContent] = [:]
  
  // Redis health tracking
  private var redisIsHealthy = true
  private var lastRedisFailure: Date?
  private let redisRetryInterval: TimeInterval = 30 // Retry Redis after 30 seconds
}

extension ChatHistory {
  
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
    // This method is now only called when Redis is already confirmed healthy
    // No need to sync here since testAndRestoreRedisConnection handles that
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
      } catch {
        logger.error("Failed to sync last response ID for user \(userID): \(error)")
      }
    }
    
    // Sync function call IDs
    for (userID, callIDs) in fallbackFunctionCallIDs {
      do {
        let key = RedisKey.functionCallIDs(userID: userID)
        // Clear existing set and add all IDs
        _ = try await redis.delete(key).get()
        if !callIDs.isEmpty {
          _ = try await redis.sadd(Array(callIDs), to: key).get()
        }
      } catch {
        logger.error("Failed to sync function call IDs for user \(userID): \(error)")
      }
    }
    
    // Sync streaming content (only non-expired)
    cleanupExpiredContent()
    for (userID, cachedContent) in fallbackStreamingContent {
      guard !cachedContent.isExpired else { continue }
      
      do {
        let key = RedisKey.streamingContent(userID: userID)
        // Clear existing list and add all data
        _ = try await redis.delete(key).get()
        if !cachedContent.data.isEmpty {
          _ = try await redis.rpush(cachedContent.data, into: key).get()
          // Set expiration based on remaining time
          let remainingTime = 3600 - Int(Date().timeIntervalSince(cachedContent.timestamp))
          if remainingTime > 0 {
            _ = try await redis.expire(key, after: .seconds(Int64(remainingTime))).get()
          }
        }
      } catch {
        logger.error("Failed to sync streaming content for user \(userID): \(error)")
      }
    }
    
    logger.info("Completed syncing fallback data to Redis")
  }
  
  // MARK: - Fallback Cleanup
  
  private func cleanupExpiredContent() {
    let expiredUsers = fallbackStreamingContent.compactMap { (userID, content) in
      content.isExpired ? userID : nil
    }
    
    for userID in expiredUsers {
      fallbackStreamingContent.removeValue(forKey: userID)
    }
  }
}

extension ChatHistory {
  
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
  
  func storeFunctionCallID(
    _ callID: String,
    for userID: UserIdentifier
  ) async throws {
    // Always store in fallback as a mirror
    if fallbackFunctionCallIDs[userID] == nil {
      fallbackFunctionCallIDs[userID] = Set<String>()
    }
    fallbackFunctionCallIDs[userID]?.insert(callID)
    
    // Try to store in Redis if it's healthy
    if shouldTryRedis() {
      do {
        let key = RedisKey.functionCallIDs(userID: userID)
        _ = try await redis.sadd(callID, to: key).get()
        markRedisHealthy()
      } catch {
        markRedisUnhealthy(error)
      }
    }
  }
  
  func removeFunctionCallID(
    _ callID: String,
    for userID: UserIdentifier
  ) async throws {
    // Always remove from fallback
    fallbackFunctionCallIDs[userID]?.remove(callID)
    
    // Try to remove from Redis if it's healthy
    if shouldTryRedis() {
      do {
        let key = RedisKey.functionCallIDs(userID: userID)
        _ = try await redis.srem(callID, from: key).get()
        markRedisHealthy()
      } catch {
        markRedisUnhealthy(error)
      }
    }
  }
  
  func getFunctionCallIDs(
    for userID: UserIdentifier
  ) async throws -> Set<String> {
    // Test and restore Redis connection if needed, then try Redis
    if await testAndRestoreRedisConnection() {
      do {
        let key = RedisKey.functionCallIDs(userID: userID)
        let members = try await redis.smembers(of: key).get()
        markRedisHealthy()
        return Set(members.compactMap { $0.string })
      } catch {
        markRedisUnhealthy(error)
      }
    }
    
    // Fall back to in-memory storage
    return fallbackFunctionCallIDs[userID] ?? Set<String>()
  }
  
  func clearFunctionCallIDs(
    for userID: UserIdentifier
  ) async throws {
    // Always clear from fallback
    fallbackFunctionCallIDs.removeValue(forKey: userID)
    
    // Try to clear from Redis if it's healthy
    if shouldTryRedis() {
      do {
        let key = RedisKey.functionCallIDs(userID: userID)
        _ = try await redis.delete(key).get()
        markRedisHealthy()
      } catch {
        markRedisUnhealthy(error)
      }
    }
  }
  
  func cacheStreamingContent<Content>(
    _ content: Content,
    userID: UserIdentifier
  ) async throws where Content: Encodable {
    let data = try encoder.encode(content)
    
    // Always cache in fallback
    cleanupExpiredContent() // Clean up expired content first
    if let existing = fallbackStreamingContent[userID] {
      var updatedData = existing.data
      updatedData.append(data)
      fallbackStreamingContent[userID] = CachedStreamingContent(data: updatedData, timestamp: existing.timestamp)
    } else {
      fallbackStreamingContent[userID] = CachedStreamingContent(data: [data], timestamp: Date())
    }
    
    // Try to cache in Redis if it's healthy
    if shouldTryRedis() {
      do {
        let key = RedisKey.streamingContent(userID: userID)
        _ = try await redis.rpush([data], into: key).get()
        _ = try await redis.expire(key, after: .seconds(3600)).get()
        markRedisHealthy()
      } catch {
        markRedisUnhealthy(error)
      }
    }
  }
  
  func flushCachedStreamingContent(
    userID: UserIdentifier
  ) async throws -> [(messageChunk: SocketMessage.MessageChunkResponse?, richMessage: SocketMessage.RichMessageResponse?)] {
    var cachedData: [Data] = []
    
    // Test and restore Redis connection if needed, then try Redis
    if await testAndRestoreRedisConnection() {
      do {
        let key = RedisKey.streamingContent(userID: userID)
        let redisData = try await redis.lrange(from: key, firstIndex: 0, lastIndex: -1).get()
        cachedData = redisData.compactMap { $0.data }
        _ = try await redis.delete(key).get()
        markRedisHealthy()
      } catch {
        markRedisUnhealthy(error)
        // Fall back to in-memory data
        cachedData = fallbackStreamingContent[userID]?.data ?? []
      }
    } else {
      // Use fallback data
      cachedData = fallbackStreamingContent[userID]?.data ?? []
    }
    
    // Always clear from fallback
    fallbackStreamingContent.removeValue(forKey: userID)
    
    guard !cachedData.isEmpty else { return [] }
    
    // Parse cached messages
    var messages: [(messageChunk: SocketMessage.MessageChunkResponse?, richMessage: SocketMessage.RichMessageResponse?)] = []
    
    for data in cachedData {
      if let messageChunk = try? decoder.decode(SocketMessage.MessageChunkResponse.self, from: data) {
        messages.append((messageChunk: messageChunk, richMessage: nil))
      } else if let richMessage = try? decoder.decode(SocketMessage.RichMessageResponse.self, from: data) {
        messages.append((messageChunk: nil, richMessage: richMessage))
      }
    }
    
    return messages
  }
  
  func clearStreamingContent(
    userID: UserIdentifier
  ) async throws {
    // Always clear from fallback
    fallbackStreamingContent.removeValue(forKey: userID)
    
    // Try to clear from Redis if it's healthy
    if shouldTryRedis() {
      do {
        let key = RedisKey.streamingContent(userID: userID)
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
    RedisKey("chat_last_response_id:\(userID)")
  }
  
  static func functionCallIDs(userID: UserIdentifier) -> RedisKey {
    RedisKey("chat_function_call_ids:\(userID)")
  }
  
  static func streamingContent(userID: UserIdentifier) -> RedisKey {
    RedisKey("chat_streaming_content:\(userID)")
  }
}
