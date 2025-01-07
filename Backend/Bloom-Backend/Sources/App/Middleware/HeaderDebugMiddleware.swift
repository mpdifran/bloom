//
//  HeaderDebugMiddleware.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-01-07.
//

import Foundation
import Vapor

final class HeaderDebugMiddleware: AsyncMiddleware {

  func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
    request.headers.forEach { header in
      request.logger.info("\(header.name): \(header.value)")
    }
    return try await next.respond(to: request)
  }
}
