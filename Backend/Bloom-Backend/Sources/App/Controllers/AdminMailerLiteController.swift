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
          $0.post("segment-free-users", use: segmentFreeUsers)
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

  @Sendable
  func segmentFreeUsers(_ request: Request) async throws -> HTTPStatus {
    guard let mailerLiteKey = request.application.mailerLiteAPIKey else {
      throw Abort(.serviceUnavailable, reason: "MAILERLITE_API_KEY not configured")
    }
    guard let revenueCatKey = request.application.revenueCatAPIKey else {
      throw Abort(.serviceUnavailable, reason: "REVENUECAT_API_KEY not configured")
    }
    guard let groupID = request.application.mailerLiteFreeUsersGroupID else {
      throw Abort(.serviceUnavailable, reason: "MAILERLITE_FREE_USERS_GROUP_ID not configured")
    }

    let mailerLiteService = MailerLiteService(
      client: request.client,
      db: request.db,
      logger: request.logger,
      apiKey: mailerLiteKey
    )

    let revenueCatService = RevenueCatService(
      client: request.client,
      logger: request.logger,
      apiKey: revenueCatKey
    )

    Task {
      do {
        request.logger.info("Starting loyal free user segmentation")

        let users = try await User.query(on: request.db)
          .filter(\.$email != nil)
          .filter(\.$appUserID != nil)
          .all()

        request.logger.info("Found \(users.count) users to check for segmentation")

        var addedCount = 0
        var skippedCount = 0
        var errorCount = 0
        let batchSize = 50

        let batches = users.chunked(into: batchSize)

        for (index, batch) in batches.enumerated() {
          for user in batch {
            guard let appUserID = user.appUserID, let email = user.email else { continue }
            do {
              let isLoyal = try await revenueCatService.isLoyalFreeUser(appUserID: appUserID)
              if isLoyal {
                try await mailerLiteService.addSubscriberToGroup(
                  email: email,
                  groupID: groupID,
                  name: user.givenName,
                  lastName: user.familyName
                )
                addedCount += 1
              } else {
                skippedCount += 1
              }
            } catch {
              errorCount += 1
              request.logger.error("Failed to check/segment user \(appUserID): \(error)")
            }
          }

          request.logger.info("[\(index + 1)/\(batches.count)] Processed batch — added: \(addedCount), skipped: \(skippedCount), errors: \(errorCount)")

          if index < batches.count - 1 {
            try await Task.sleep(for: .seconds(5))
          }
        }

        request.logger.info("Free user segmentation completed — added: \(addedCount), skipped: \(skippedCount), errors: \(errorCount)")
      } catch {
        request.logger.error("Free user segmentation failed: \(error)")
      }
    }

    return .ok
  }
}
