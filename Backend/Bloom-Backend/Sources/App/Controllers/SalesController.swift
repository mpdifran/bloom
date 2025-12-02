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
    let user = try request.auth.require(User.self)
    let now = Date()

    // Determine user's target audience
    let userAudience = try await determineUserAudience(user: user, request: request)

    // Query active sales
    let sales = try await SaleRecord.query(on: request.db)
      .filter(\.$isActive == true)
      .filter(\.$startDate <= now)
      .filter(\.$endDate >= now)
      .group(.or) { group in
        group.filter(\.$targetAudience == .allUsers)
        group.filter(\.$targetAudience == userAudience)
      }
      .all()

    return SalesResponse(sales: sales.map { $0.asDetails() })
  }

  @Sendable
  func determineUserAudience(user: User, request: Request) async throws -> SaleRecord.TargetAudienceEnum {
    // Check if user has an active subscription via their appUserID
    guard user.appUserID != nil else {
      // No RevenueCat ID means they're a free user
      return .freeUsers
    }

    // TODO: Implement subscription status check
    // For now, we'll return freeUsers as the default
    // In a future update, we should:
    // 1. Call RevenueCat API to check subscription status
    // 2. Or store subscription status in the User model
    // 3. Determine if user is:
    //    - freeUsers: Never subscribed
    //    - subscribedUsers: Currently has active subscription
    //    - expiredUsers: Had subscription, now expired

    return .freeUsers
  }
}
