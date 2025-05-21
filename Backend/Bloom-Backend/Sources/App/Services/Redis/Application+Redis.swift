//
//  Application+Redis.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-14.
//

import Vapor
import Redis

extension Application {

//  func setupRedis() throws {
//    if let redisURL {
//      redis.configuration = try RedisConfiguration(url: redisURL)
//    } else {
//      redis.configuration = try RedisConfiguration(
//        hostname: redisHostname,
//        port: redisPort,
//        password: redisPassword
//      )
//    }
//  }

  func setupRedis() throws {
    if let redisURL {
      var tlsConfig: TLSConfiguration? = nil

      if redisURL.absoluteString.starts(with: "rediss://") {
        // Accept self-signed certs
        tlsConfig = .makeClientConfiguration()
        tlsConfig?.certificateVerification = .none
      }

      redis.configuration = try RedisConfiguration(
        url: redisURL,
        tlsConfiguration: tlsConfig
      )
    } else {
      redis.configuration = try RedisConfiguration(
        hostname: redisHostname,
        port: redisPort,
        password: redisPassword
      )
    }
  }
}
