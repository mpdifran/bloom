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

  private let baseURL = "https://connect.mailerlite.com"
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

  func removeSubscriberFromGroup(email: String, groupID: String) async throws {
    let uri = URI(string: "\(baseURL)/api/subscribers/\(email)/groups/\(groupID)")

    var headers = HTTPHeaders()
    headers.add(name: .authorization, value: "Bearer \(apiKey)")
    headers.add(name: .accept, value: "application/json")

    let response = try await client.delete(uri, headers: headers)

    guard (200..<300).contains(response.status.code) else {
      let body = response.body.map { String(buffer: $0) } ?? "empty"
      throw Abort(.internalServerError, reason: "MailerLite API returned \(response.status.code): \(body)")
    }

    logger.info("Removed subscriber \(email) from MailerLite group \(groupID)")
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

