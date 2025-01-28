//
//  NetworkError.swift
//  Gardener
//
//  Created by Haocen Jiang on 2025-01-27.
//

import Foundation

enum NetworkError: LocalizedError {
  case invalidResponse
  case serverError(statusCode: Int, message: String?)
  
  var errorDescription: String? {
    switch self {
    case .invalidResponse:
      return "The server response was invalid."
    case .serverError(let statusCode, let message):
      return message ?? "Server error with status code \(statusCode)."
    }
  }
}
