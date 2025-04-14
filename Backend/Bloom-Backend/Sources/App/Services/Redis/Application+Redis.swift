//
//  Application+Redis.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-14.
//

import Vapor
import Redis

extension Application {

  func setupRedis() throws {
    if let redisURL {
      redis.configuration = try RedisConfiguration(url: redisURL)
    } else {
      redis.configuration = try RedisConfiguration(
        hostname: redisHostname,
        port: redisPort,
        password: redisPassword
      )
    }
  }
}
