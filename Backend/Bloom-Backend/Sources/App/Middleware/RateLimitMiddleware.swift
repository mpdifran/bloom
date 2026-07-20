//
//  RateLimitMiddleware.swift
//  Bloom-Backend
//
//  Redis-backed fixed-window rate limiter. Keyed by bearer token when present,
//  otherwise client IP. Limits are intentionally generous — the goal is to stop
//  runaway abuse (a script hammering the paid-AI endpoints), not to throttle
//  normal use. Tighten `limit`/`window` if abuse is observed.
//

import Vapor
import Redis

struct RateLimitMiddleware: AsyncMiddleware {

  /// Max requests allowed per identifier within `window`.
  let limit: Int
  /// Window length in seconds.
  let window: Int

  init(limit: Int = 240, window: Int = 60) {
    self.limit = limit
    self.window = window
  }

  func respond(
    to request: Request,
    chainingTo next: any AsyncResponder
  ) async throws -> Response {
    let identifier = Self.identifier(for: request)
    let key = RedisKey("ratelimit:\(window):\(identifier)")

    let count: Int
    do {
      count = try await request.redis.increment(key).get()
      if count == 1 {
        _ = try await request.redis.expire(key, after: .seconds(Int64(window))).get()
      }
    } catch {
      // Fail open: never let a Redis hiccup take down the API.
      request.logger.warning("Rate limiter unavailable, allowing request: \(error)")
      return try await next.respond(to: request)
    }

    guard count <= limit else {
      request.logger.notice("Rate limit exceeded for \(identifier) (\(count)/\(limit) per \(window)s)")
      throw Abort(.tooManyRequests, reason: "Too many requests. Please slow down.")
    }

    return try await next.respond(to: request)
  }

  private static func identifier(for request: Request) -> String {
    if let bearer = request.headers.bearerAuthorization?.token {
      // Hash so raw tokens never become Redis keys / land in logs.
      return "t:\(SHA256.hash(data: Data(bearer.utf8)).hexEncoded)"
    }
    let ip = request.headers.first(name: .xForwardedFor)?
      .split(separator: ",").first.map(String.init)?
      .trimmingCharacters(in: .whitespaces)
      ?? request.remoteAddress?.ipAddress
      ?? "unknown"
    return "ip:\(ip)"
  }
}

private extension SHA256.Digest {
  var hexEncoded: String {
    map { String(format: "%02x", $0) }.joined()
  }
}
