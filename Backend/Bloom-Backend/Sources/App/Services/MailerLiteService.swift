//
//  MailerLiteService.swift
//  Bloom-Backend
//

import Foundation
import Vapor
import Fluent

struct MailerLiteService {
  let client: Client
  let db: any Database
  let logger: Logger
  let apiKey: String

  private let batchSize = 50
  private let baseURL = "https://connect.mailerlite.com"

  func syncAllSubscribers() async throws {
    logger.info("Fetching users with emails for MailerLite sync")

    let users = try await User.query(on: db)
      .filter(\.$email != nil)
      .all()

    logger.info("Found \(users.count) users with emails to sync to MailerLite")

    guard !users.isEmpty else { return }

    var successCount = 0
    var failureCount = 0

    let batches = users.chunked(into: batchSize)

    for (index, batch) in batches.enumerated() {
      for user in batch {
        guard let email = user.email else { continue }
        do {
          try await upsertSubscriber(email: email, name: user.givenName, lastName: user.familyName)
          successCount += 1
        } catch {
          failureCount += 1
          logger.error("Failed to upsert subscriber \(email): \(error)")
        }
      }

      logger.info("[\(index + 1)/\(batches.count)] Synced batch of \(batch.count) subscribers")

      // Pause between batches to avoid rate limiting
      if index < batches.count - 1 {
        try await Task.sleep(for: .seconds(5))
      }
    }

    logger.info("MailerLite sync completed — synced: \(successCount), failed: \(failureCount)")
  }
}

// MARK: - Groups

extension MailerLiteService {

  func addSubscriberToGroup(email: String, groupID: String, name: String? = nil, lastName: String? = nil) async throws {
    // Upsert the subscriber first to ensure they exist
    try await upsertSubscriber(email: email, name: name, lastName: lastName)

    let uri = URI(string: "\(baseURL)/api/subscribers/\(email)/groups/\(groupID)")

    var headers = HTTPHeaders()
    headers.add(name: .authorization, value: "Bearer \(apiKey)")
    headers.add(name: .contentType, value: "application/json")
    headers.add(name: .accept, value: "application/json")

    let response = try await client.post(uri, headers: headers)

    guard (200..<300).contains(response.status.code) else {
      let body = response.body.map { String(buffer: $0) } ?? "empty"
      throw Abort(.internalServerError, reason: "MailerLite API returned \(response.status.code): \(body)")
    }

    logger.info("Added subscriber \(email) to MailerLite group \(groupID)")
  }

  func upsertSubscriber(email: String, name: String? = nil, lastName: String? = nil) async throws {
    let uri = URI(string: "\(baseURL)/api/subscribers")

    var headers = HTTPHeaders()
    headers.add(name: .authorization, value: "Bearer \(apiKey)")
    headers.add(name: .contentType, value: "application/json")
    headers.add(name: .accept, value: "application/json")

    let body = UpsertSubscriberRequest(
      email: email,
      fields: Fields(name: name, last_name: lastName)
    )

    let response = try await client.post(uri, headers: headers, content: body)

    guard (200..<300).contains(response.status.code) else {
      let responseBody = response.body.map { String(buffer: $0) } ?? "empty"
      throw Abort(.internalServerError, reason: "MailerLite upsert returned \(response.status.code): \(responseBody)")
    }
  }
}

// MARK: - Models

private extension MailerLiteService {

  struct UpsertSubscriberRequest: Content {
    let email: String
    let fields: Fields
  }

  struct Fields: Content {
    let name: String?
    let last_name: String?
  }
}

