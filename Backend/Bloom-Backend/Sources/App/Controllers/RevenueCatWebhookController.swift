//
//  RevenueCatWebhookController.swift
//  Bloom-Backend
//

import Vapor
import Fluent

struct RevenueCatWebhookController { }

extension RevenueCatWebhookController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1") {
      $0.group("webhook") {
        $0.post("revenuecat", use: handleWebhook)
      }
    }
  }
}

private extension RevenueCatWebhookController {

  @Sendable
  func handleWebhook(_ request: Request) async throws -> HTTPStatus {
    guard let secret = request.application.revenueCatWebhookSecret else {
      request.logger.warning("REVENUECAT_WEBHOOK_SECRET not configured, rejecting webhook")
      throw Abort(.serviceUnavailable)
    }

    let authHeader = request.headers.first(name: .authorization) ?? ""
    guard authHeader == secret else {
      request.logger.warning("RevenueCat webhook received with invalid authorization")
      throw Abort(.unauthorized)
    }

    let payload = try request.content.decode(RevenueCatWebhookPayload.self)
    let eventType = payload.event.type

    request.logger.info("Received RevenueCat webhook: \(eventType)")

    switch eventType {
    case "CANCELLATION":
      try await handleCancellation(request: request, appUserID: payload.event.appUserID)
    default:
      break
    }

    return .ok
  }

  func handleCancellation(request: Request, appUserID: String) async throws {
    guard let user = try await User.query(on: request.db)
      .filter(\.$appUserID == appUserID)
      .first() else {
      request.logger.warning("RevenueCat cancellation: no user found for appUserID \(appUserID)")
      return
    }

    guard let email = user.email else {
      request.logger.info("RevenueCat cancellation: user \(appUserID) has no email, skipping MailerLite")
      return
    }

    guard let apiKey = request.application.mailerLiteAPIKey,
          let groupID = request.application.mailerLiteCancelledGroupID else {
      request.logger.warning("MailerLite API key or cancelled group ID not configured, skipping")
      return
    }

    let mailerLiteService = MailerLiteService(
      client: request.client,
      db: request.db,
      logger: request.logger,
      apiKey: apiKey
    )

    try await mailerLiteService.addSubscriberToGroup(email: email, groupID: groupID)
    request.logger.info("RevenueCat cancellation: added \(email) to cancelled group in MailerLite")
  }
}

// MARK: - Webhook Payload

private extension RevenueCatWebhookController {

  struct RevenueCatWebhookPayload: Content {
    let event: Event

    struct Event: Content {
      let type: String
      let appUserID: String

      enum CodingKeys: String, CodingKey {
        case type
        case appUserID = "app_user_id"
      }
    }
  }
}
