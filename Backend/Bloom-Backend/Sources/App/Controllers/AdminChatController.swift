//
//  AdminChatController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-06-11.
//

import Foundation
import Vapor
import Fluent
import BloomModel

struct AdminChatController { }

extension AdminChatController: RouteCollection {
  
  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1", "admin") {
      $0.auth(using: AdminUserToken.self) {
        $0.group("chat") {
          $0.get("issue-reports", use: getIssueReports)
        }
      }
    }
  }
}

extension AdminChatController {
  
  @Sendable
  func getIssueReports(_ request: Request) async throws -> AdminChatIssueReportsResponse {
    let limit = max(1, min(500, request.query[Int.self, at: "limit"] ?? 100))
    let offset = max(0, request.query[Int.self, at: "offset"] ?? 0)
    
    // Get total count
    let totalCount = try await ChatMessageIssueReport.query(on: request.db).count()
    
    // Get paginated results with user relationship
    let reports = try await ChatMessageIssueReport.query(on: request.db)
      .with(\.$user)
      .sort(\.$createdAt, .descending)
      .offset(offset)
      .limit(limit)
      .all()
    
    // Convert to response models
    let adminReports = reports.compactMap { report -> AdminChatIssueReport? in
      guard let id = report.id, let createdAt = report.createdAt else {
        return nil
      }
      
      return AdminChatIssueReport(
        id: id,
        responseID: report.responseID,
        notes: report.notes,
        isAnonymous: report.$user.id == nil,
        userID: report.$user.id,
        createdAt: createdAt
      )
    }
    
    return AdminChatIssueReportsResponse(
      reports: adminReports,
      totalCount: totalCount
    )
  }
}
