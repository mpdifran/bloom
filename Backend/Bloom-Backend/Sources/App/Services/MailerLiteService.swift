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

    let subscribers = users.compactMap { user -> Subscriber? in
      guard let email = user.email else { return nil }
      return Subscriber(
        email: email,
        fields: Fields(
          name: user.givenName,
          last_name: user.familyName
        )
      )
    }

    let batches = subscribers.chunked(into: batchSize)

    var successCount = 0
    var failureCount = 0

    for (index, batch) in batches.enumerated() {
      do {
        try await importBatch(batch)
        successCount += batch.count
        logger.info("[\(index + 1)/\(batches.count)] Synced batch of \(batch.count) subscribers")
      } catch {
        failureCount += batch.count
        logger.error("[\(index + 1)/\(batches.count)] Failed to sync batch: \(error)")
      }
    }

    logger.info("MailerLite sync completed — synced: \(successCount), failed: \(failureCount)")
  }
}

// MARK: - API

private extension MailerLiteService {

  func importBatch(_ subscribers: [Subscriber]) async throws {
    let uri = URI(string: "\(baseURL)/api/subscribers/import")
    let requestBody = SubscriberImportRequest(subscribers: subscribers)

    var headers = HTTPHeaders()
    headers.add(name: .authorization, value: "Bearer \(apiKey)")
    headers.add(name: .contentType, value: "application/json")
    headers.add(name: .accept, value: "application/json")

    let response = try await client.post(uri, headers: headers, content: requestBody)

    guard (200..<300).contains(response.status.code) else {
      let body = response.body.map { String(buffer: $0) } ?? "empty"
      throw Abort(.internalServerError, reason: "MailerLite API returned \(response.status.code): \(body)")
    }
  }
}

// MARK: - Groups

extension MailerLiteService {

  func addSubscriberToGroup(email: String, groupID: String) async throws {
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
}

// MARK: - Models

private extension MailerLiteService {

  struct SubscriberImportRequest: Content {
    let subscribers: [Subscriber]
  }

  struct Subscriber: Content {
    let email: String
    let fields: Fields
  }

  struct Fields: Content {
    let name: String?
    let last_name: String?
  }
}

