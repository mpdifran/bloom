//
//  SalesController.swift
//  Bloom-Backend
//
//  Created by Claude on 2025-12-02.
//

import Foundation
import Vapor
import Fluent
import BloomModel

struct SalesController { }

extension SalesController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1") {
      $0.auth(using: UserToken.self) {
        $0.group("sales") {
          $0.get("active", use: getActiveSales)
        }
      }
    }
  }
}

private extension SalesController {

  @Sendable
  func getActiveSales(_ request: Request) async throws -> Response {
    _ = try request.auth.require(User.self)

    // Query all active sales
    // Client will filter based on date range and user's subscription status
    let sales = try await SaleRecord.query(on: request.db)
      .filter(\.$isActive == true)
      .all()

    let response = SalesResponse(sales: sales.map { $0.asDetails() })
    let data = try JSONEncoder.bloomModel.encode(response)

    return Response(
      status: .ok,
      headers: ["Content-Type": "application/json"],
      body: .init(data: data)
    )
  }
}
