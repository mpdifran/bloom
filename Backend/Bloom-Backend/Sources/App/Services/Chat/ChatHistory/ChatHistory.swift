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

final actor ChatHistory {

  init(redis: RedisClient) {
    self.redis = redis
  }

  private let redis: RedisClient
  private let encoder = JSONEncoder.bloomModel
  private let decoder = JSONDecoder.bloomModel
}

extension ChatHistory {

  func append(
    userID: UserIdentifier,
    inputItems: [OpenAIKit.Response.InputItem]
  ) async throws {
    let data = try inputItems.map(encoder.encode)
    let key = RedisKey.chatHistory(userID: userID)
    _ = try await redis.rpush(data, into: key).get()
    _ = try await redis.ltrim(key, before: -.historyLimit, after: -1).get()
  }

  func load(
    for userID: UserIdentifier
  ) async throws -> [OpenAIKit.Response.InputItem] {
    let redisValues = try await redis.lrange(
      from: .chatHistory(userID: userID),
      firstIndex: 0,
      lastIndex: -1
    ).get()

    return try redisValues.map { value in
      guard let data = value.data else {
        throw Abort(.internalServerError, reason: "Invalid Redis value")
      }
      return try decoder.decode(OpenAIKit.Response.InputItem.self, from: data)
    }
  }

  func clearHistory(for userID: UserIdentifier) async throws {
    _ = try await redis.delete(.chatHistory(userID: userID)).get()
  }
  
  func storeLastResponseID(
    _ responseID: String,
    for userID: UserIdentifier
  ) async throws {
    let key = RedisKey.lastResponseID(userID: userID)
    _ = try await redis.set(key, to: responseID).get()
  }
  
  func getLastResponseID(
    for userID: UserIdentifier
  ) async throws -> String? {
    let key = RedisKey.lastResponseID(userID: userID)
    return try await redis.get(key).get().string
  }
  
  func clearLastResponseID(
    for userID: UserIdentifier
  ) async throws {
    let key = RedisKey.lastResponseID(userID: userID)
    _ = try await redis.delete(key).get()
  }
  
  func storeFunctionCallID(
    _ callID: String,
    for userID: UserIdentifier
  ) async throws {
    let key = RedisKey.functionCallIDs(userID: userID)
    _ = try await redis.sadd(callID, to: key).get()
  }
  
  func removeFunctionCallID(
    _ callID: String,
    for userID: UserIdentifier
  ) async throws {
    let key = RedisKey.functionCallIDs(userID: userID)
    _ = try await redis.srem(callID, from: key).get()
  }
  
  func getFunctionCallIDs(
    for userID: UserIdentifier
  ) async throws -> Set<String> {
    let key = RedisKey.functionCallIDs(userID: userID)
    let members = try await redis.smembers(of: key).get()
    return Set(members.compactMap { $0.string })
  }
  
  func clearFunctionCallIDs(
    for userID: UserIdentifier
  ) async throws {
    let key = RedisKey.functionCallIDs(userID: userID)
    _ = try await redis.delete(key).get()
  }
  
  func cacheStreamingContent<Content>(
    _ content: Content,
    userID: UserIdentifier
  ) async throws where Content: Encodable {
    let key = RedisKey.streamingContent(userID: userID)
    let data = try encoder.encode(content)
    
    // Push to Redis list (queue)
    _ = try await redis.rpush([data], into: key).get()
    
    // Set expiration to 1 hour
    _ = try await redis.expire(key, after: .seconds(3600)).get()
  }
  
  func flushCachedStreamingContent(
    userID: UserIdentifier
  ) async throws -> [(messageChunk: SocketMessage.MessageChunkResponse?, richMessage: SocketMessage.RichMessageResponse?)] {
    let key = RedisKey.streamingContent(userID: userID)
    
    // Get all cached messages
    let cachedData = try await redis.lrange(from: key, firstIndex: 0, lastIndex: -1).get()
    
    guard !cachedData.isEmpty else { return [] }
    
    // Parse cached messages
    var messages: [(messageChunk: SocketMessage.MessageChunkResponse?, richMessage: SocketMessage.RichMessageResponse?)] = []
    
    for value in cachedData {
      guard let data = value.data else { continue }
      
      if let messageChunk = try? decoder.decode(SocketMessage.MessageChunkResponse.self, from: data) {
        messages.append((messageChunk: messageChunk, richMessage: nil))
      } else if let richMessage = try? decoder.decode(SocketMessage.RichMessageResponse.self, from: data) {
        messages.append((messageChunk: nil, richMessage: richMessage))
      }
    }
    
    // Clear the cache
    _ = try await redis.delete(key).get()
    
    return messages
  }
  
  func clearStreamingContent(
    userID: UserIdentifier
  ) async throws {
    let key = RedisKey.streamingContent(userID: userID)
    _ = try await redis.delete(key).get()
  }
}

private extension RedisKey {

  static func chatHistory(userID: UserIdentifier) -> RedisKey {
    RedisKey("chat_history:\(userID)")
  }
  
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
