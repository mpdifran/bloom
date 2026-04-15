//
//  AdminMailerLiteController.swift
//  Bloom-Backend
//

import Vapor
import Fluent

struct AdminMailerLiteController { }

extension AdminMailerLiteController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1", "admin") {
      $0.auth(using: AdminUserToken.self) {
        $0.group("mailerlite") {
          $0.post("sync", use: syncSubscribers)
        }
      }
    }
  }
}

private extension AdminMailerLiteController {

  @Sendable
  func syncSubscribers(_ request: Request) async throws -> HTTPStatus {
    guard let apiKey = request.application.mailerLiteAPIKey else {
      throw Abort(.serviceUnavailable, reason: "MAILERLITE_API_KEY not configured")
    }

    let mailerLiteService = MailerLiteService(
      client: request.client,
      db: request.db,
      logger: request.logger,
      apiKey: apiKey
    )

    Task {
      do {
        try await mailerLiteService.syncAllSubscribers()
        request.logger.info("MailerLite sync completed successfully")
      } catch {
        request.logger.error("MailerLite sync failed: \(error)")
      }
    }

    return .ok
  }
}
