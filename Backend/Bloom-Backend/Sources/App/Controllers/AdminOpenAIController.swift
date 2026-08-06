//
//  AdminOpenAIController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-05-24.
//

import Foundation
import Vapor
@preconcurrency import OpenAIKit

struct AdminOpenAIController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1", "admin") {
      $0.adminAuth {
        $0.get("list-models", use: listModels)
      }
    }
  }
}

private extension AdminOpenAIController {

  @Sendable
  func listModels(_ request: Request) async throws -> [Model] {
    try await request.openAI.models.list()
  }
}

extension Model: @retroactive AsyncResponseEncodable {}
extension Model: @retroactive AsyncRequestDecodable {}
extension Model: @retroactive ResponseEncodable {}
extension Model: @retroactive RequestDecodable {}
extension Model: @retroactive Content { }
