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
}

private extension RedisKey {

  static func chatHistory(userID: UserIdentifier) -> RedisKey {
    RedisKey("chat_history:\(userID)")
  }
}
