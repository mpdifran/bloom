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
  func getActiveSales(_ request: Request) async throws -> SalesResponse {
    _ = try request.auth.require(User.self)
    let now = Date()

    // Query all active sales within their date range
    // Client will filter based on user's subscription status
    let sales = try await SaleRecord.query(on: request.db)
      .filter(\.$isActive == true)
      .filter(\.$startDate <= now)
      .filter(\.$endDate >= now)
      .all()

    return SalesResponse(sales: sales.map { $0.asDetails() })
  }
}
