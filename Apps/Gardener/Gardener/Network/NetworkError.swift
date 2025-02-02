//
//  NetworkError.swift
//  Gardener
//
//  Created by Haocen Jiang on 2025-01-27.
//

import Foundation

enum NetworkError: LocalizedError {
  case invalidResponse
  case serverError(statusCode: Int, errorResponse: NetworkErrorResponse?)
  
  var errorDescription: String? {
    switch self {
    case .invalidResponse:
      return "The server response was invalid."
    case .serverError(let statusCode, let errorResponse):
      return "Server error with status code \(statusCode), reason: \(errorResponse?.reason ?? "N/A")"
    }
  }
}

/// Codeable representation for what the error response looks like
/// https://github.com/vapor/vapor/blob/8589cb562feab069f2563bdcdeb8f9608a07a2c7/Sources/Vapor/Middleware/ErrorMiddleware.swift#L8
struct NetworkErrorResponse: Codable {
  /// Always `true` to indicate this is a non-typical JSON response.
  var error: Bool

  /// The reason for the error.
  var reason: String
}
