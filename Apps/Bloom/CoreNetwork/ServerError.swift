//
//  ServerError.swift
//  CoreNetwork
//
//  Created by Claude on 2026-08-05.
//

import Foundation
import BloomModel

/// A typed error decoded from a Vapor `Abort` response body.
///
/// The backend returns non-2xx failures as `{ "error": true, "reason": "<message>" }`. This type
/// preserves the server's user-facing `reason` so the shared `.alert(error:)` path can display it
/// verbatim (e.g. "You've reached today's AI usage limit. Please try again tomorrow.") instead of a
/// generic decoding failure.
public struct ServerError: LocalizedError, Sendable {

  public let statusCode: Int
  public let reason: String

  public var errorDescription: String? { reason }

  init(statusCode: Int, reason: String) {
    self.statusCode = statusCode
    self.reason = reason
  }

  /// Vapor's error envelope.
  private struct Payload: Decodable {
    let error: Bool
    let reason: String
  }

  /// Builds a `ServerError` from a response body, or `nil` if the body isn't a Vapor error envelope.
  static func decode(statusCode: Int, data: Data) -> ServerError? {
    guard
      let payload = try? JSONDecoder.bloomModel.decode(Payload.self, from: data),
      payload.error
    else {
      return nil
    }
    return ServerError(statusCode: statusCode, reason: payload.reason)
  }
}
