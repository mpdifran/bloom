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
import OpenAIKit

struct AdminChatController { }

extension AdminChatController: RouteCollection {
  
  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1", "admin") {
      $0.auth(using: AdminUserToken.self) {
        $0.group("chat") {
          $0.get("issue-reports", use: getIssueReports)
          $0.get("issue-reports", ":reportID", "messages", use: getIssueReportMessages)
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
      
      let isAnonymous = report.$user.id == nil
      let userName: String?
      
      if isAnonymous {
        userName = nil
      } else if let user = report.user {
        // Combine given name and family name
        let givenName = user.givenName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let familyName = user.familyName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if !givenName.isEmpty || !familyName.isEmpty {
          userName = [givenName, familyName].filter { !$0.isEmpty }.joined(separator: " ")
        } else {
          userName = "Unknown User"
        }
      } else {
        userName = "Unknown User"
      }
      
      return AdminChatIssueReport(
        id: id,
        responseID: report.responseID,
        notes: report.notes,
        isAnonymous: isAnonymous,
        userID: report.$user.id,
        userName: userName,
        createdAt: createdAt
      )
    }
    
    return AdminChatIssueReportsResponse(
      reports: adminReports,
      totalCount: totalCount
    )
  }
  
  @Sendable
  func getIssueReportMessages(_ request: Request) async throws -> AdminChatIssueReportMessagesResponse {
    guard let reportID = request.parameters.get("reportID") else {
      throw Abort(.badRequest, reason: "Report ID is required")
    }
    
    // Fetch the report to get the responseID
    guard let report = try await ChatMessageIssueReport.find(reportID, on: request.db) else {
      throw Abort(.notFound, reason: "Report not found")
    }
    
    // Fetch the response from OpenAI
    let isAnonymous = report.$user.id == nil
    let messages = try await fetchMessagesFromOpenAI(
      responseID: report.responseID,
      isAnonymous: isAnonymous,
      request: request
    )
    
    return AdminChatIssueReportMessagesResponse(
      reportID: reportID,
      messages: messages
    )
  }
  
  private func fetchMessagesFromOpenAI(
    responseID: String,
    isAnonymous: Bool,
    request: Request
  ) async throws -> [AdminChatMessage] {
    do {
      // Fetch the response and input items from OpenAI
      let response = try await request.openAI.responses.getResponse(responseID: responseID)
      let inputItems = try await request.openAI.responses.listInputItems(responseID: responseID)

      var messages: [AdminChatMessage] = []
      
      // Process input items (user messages) - reverse to get chronological order
      for inputItem in inputItems.data.reversed() {
        switch inputItem {
        case .message(let message):
          // Skip system messages for anonymous reports
          if isAnonymous && message.role == .system {
            continue
          }
          
          for content in message.content {
            switch content {
            case .text(let text):
              messages.append(AdminChatMessage(
                id: message.id ?? UUID().uuidString,
                role: message.role.rawValue,
                content: text.text
              ))
            case .image(let image):
              messages.append(AdminChatMessage(
                id: message.id ?? UUID().uuidString,
                role: message.role.rawValue,
                content: nil,
                imageFileID: image.fileId
              ))
            default:
              break
            }
          }
        default:
          break
        }
      }
      
      // Process output items (assistant messages)
      for output in response.output {
        switch output {
        case .message(let message):
          if let textContent = message.content.first(where: { content in
            if case .outputText = content { return true }
            return false
          }) {
            if case .outputText(let text) = textContent {
              messages.append(AdminChatMessage(
                id: message.id,
                role: message.role.rawValue,
                content: text.text
              ))
            }
          }
        default:
          break
        }
      }
      
      return messages
    } catch {
      request.logger.error("Failed to fetch messages from OpenAI: \(error)")
      throw Abort(.serviceUnavailable, reason: "Unable to fetch chat messages")
    }
  }
}
