//
//  RevenueCatService.swift
//  Bloom-Backend
//

import Foundation
import Vapor

struct RevenueCatService {
  let client: Client
  let logger: Logger
  let apiKey: String

  private let baseURL = "https://api.revenuecat.com"

  func isLoyalFreeUser(appUserID: String) async throws -> Bool {
    let subscriber = try await getSubscriber(appUserID: appUserID)

    let hasPaid = !subscriber.subscriptions.isEmpty
    guard !hasPaid else { return false }

    guard let firstSeen = subscriber.firstSeen, let lastSeen = subscriber.lastSeen else {
      return false
    }

    let daysBetween = Calendar.current.dateComponents([.day], from: firstSeen, to: lastSeen).day ?? 0
    return daysBetween >= 30
  }
}

// MARK: - API

private extension RevenueCatService {

  func getSubscriber(appUserID: String) async throws -> SubscriberInfo {
    let encodedID = appUserID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? appUserID
    let uri = URI(string: "\(baseURL)/v1/subscribers/\(encodedID)")

    var headers = HTTPHeaders()
    headers.add(name: .authorization, value: "Bearer \(apiKey)")
    headers.add(name: .accept, value: "application/json")

    let response = try await client.get(uri, headers: headers)

    guard (200..<300).contains(response.status.code) else {
      let body = response.body.map { String(buffer: $0) } ?? "empty"
      throw Abort(.internalServerError, reason: "RevenueCat API returned \(response.status.code): \(body)")
    }

    let wrapper = try response.content.decode(SubscriberResponse.self)
    return wrapper.subscriber
  }
}

// MARK: - Models

private extension RevenueCatService {

  struct SubscriberResponse: Content {
    let subscriber: SubscriberInfo
  }

  struct SubscriberInfo: Content {
    let firstSeen: Date?
    let lastSeen: Date?
    let subscriptions: [String: SubscriptionInfo]

    enum CodingKeys: String, CodingKey {
      case firstSeen = "first_seen"
      case lastSeen = "last_seen"
      case subscriptions
    }
  }

  struct SubscriptionInfo: Content { }
}
