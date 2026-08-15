//
//  NotificationService.swift
//  Bloom-Backend
//
//  Created by Assistant on 2025-07-27.
//

import Foundation
import Vapor
import Fluent
import APNS
import VaporAPNS
import APNSCore

struct NotificationService {
  let application: Application
  let logger: Logger
  
  init(application: Application) {
    self.application = application
    self.logger = application.logger
  }
  
  func sendMorningReportNotifications(db: Database) async throws {
    let now = Date()
    var utcCalendar = Calendar.current
    utcCalendar.timeZone = TimeZone(identifier: "UTC")!
    
    // Get current UTC time rounded to nearest 5 minutes
    let components = utcCalendar.dateComponents([.hour, .minute], from: now)
    guard let currentHour = components.hour,
          let currentMinute = components.minute else {
      logger.error("Failed to get current UTC time components")
      return
    }
    
    // Round to nearest 5 minutes
    let roundedMinute = Int((Double(currentMinute) / 5.0).rounded()) * 5
    
    // Query users who should receive notifications at this UTC time
    let users = try await User.query(on: db)
      .filter(\.$morningNotificationHour == currentHour)
      .filter(\.$morningNotificationMinute == roundedMinute)
      .filter(\.$apnsDeviceToken != nil)
      .all()
    
    logger.info("Found \(users.count) users scheduled for notifications at \(currentHour):\(String(format: "%02d", roundedMinute)) UTC")
    
    for user in users {
      guard let deviceToken = user.apnsDeviceToken else {
        continue
      }
      
      do {
        try await sendMorningReportNotification(to: user, deviceToken: deviceToken)
        logger.info("Sent morning report notification to user \(user.id?.value ?? "")")
      } catch {
        logger.error("Failed to send notification to user \(user.id?.value ?? ""): \(error)")
      }
    }
  }
  
  private func sendMorningReportNotification(to user: User, deviceToken: String) async throws {
    let expirationTime = Int(Date().addingTimeInterval(3600).timeIntervalSince1970)
    let expiration = APNSNotificationExpiration.timeIntervalSince1970InSeconds(expirationTime)
    let priority = APNSPriority.immediately
    let topic = application.bloomAppBundleID

    // Create payload for morning report trigger
    struct MorningReportTrigger: Codable {
      let type: String
    }

    let payload = MorningReportTrigger(type: "morning_report")

    let silentNotification = APNSBackgroundNotification(
      expiration: expiration,
      topic: topic,
      payload: payload
    )

    let result = try await application.apns.client.send(
      APNSRequest(
        message: silentNotification,
        deviceToken: deviceToken,
        pushType: .background,
        expiration: expiration,
        priority: priority,
        apnsID: nil,
        topic: topic,
        collapseID: nil
      )
    )

    if let apnsUniqueID = result.apnsUniqueID {
      logger.debug("Sent morning report notification to user \(user.id?.value ?? ""): \(apnsUniqueID)")
    }
  }

  func sendTestNotification(to user: User, deviceToken: String) async throws {
    let expirationTime = Int(Date().addingTimeInterval(3600).timeIntervalSince1970)
    let expiration = APNSNotificationExpiration.timeIntervalSince1970InSeconds(expirationTime)
    let priority = APNSPriority.immediately
    let topic = application.bloomAppBundleID

    // Create payload for test notification with timestamp
    struct TestNotificationPayload: Codable {
      let type: String
      let timestamp: String
    }

    let iso8601Formatter = ISO8601DateFormatter()
    let payload = TestNotificationPayload(
      type: "test_notification",
      timestamp: iso8601Formatter.string(from: Date())
    )

    let silentNotification = APNSBackgroundNotification(
      expiration: expiration,
      topic: topic,
      payload: payload
    )

    let result = try await application.apns.client.send(
      APNSRequest(
        message: silentNotification,
        deviceToken: deviceToken,
        pushType: .background,
        expiration: expiration,
        priority: priority,
        apnsID: nil,
        topic: topic,
        collapseID: nil
      )
    )

    if let apnsUniqueID = result.apnsUniqueID {
      logger.info("Sent test notification to user \(user.id?.value ?? "") with APNS ID: \(apnsUniqueID)")
    }
  }

  func sendIssueReportAcceptedNotification(
    to user: User,
    deviceToken: String,
    foodItemName: String?
  ) async throws {
    let expirationTime = Int(Date().addingTimeInterval(86400).timeIntervalSince1970)
    let expiration = APNSNotificationExpiration.timeIntervalSince1970InSeconds(expirationTime)
    let priority = APNSPriority.immediately
    let topic = application.bloomAppBundleID

    // loc-key rather than literal text: iOS resolves these against the app's own String Catalog in
    // whichever language the user's app is running in, so the server never needs to know the locale
    // and the strings live in one place. The keys are declared in RemoteNotificationString on the
    // client - if one is renamed there without being renamed here, the user sees the raw key.
    let foodName = foodItemName ?? ""
    let alert = APNSAlertNotificationContent(
      title: .localized(key: "notification.issueReportAccepted.title", arguments: []),
      body: .localized(key: "notification.issueReportAccepted.body", arguments: [foodName])
    )

    struct IssueReportAcceptedPayload: Codable {
      let type: String
    }

    let payload = IssueReportAcceptedPayload(type: "issue_report_accepted")

    let alertNotification = APNSAlertNotification(
      alert: alert,
      expiration: expiration,
      priority: priority,
      topic: topic,
      payload: payload
    )

    let result = try await application.apns.client.send(
      APNSRequest(
        message: alertNotification,
        deviceToken: deviceToken,
        pushType: .alert,
        expiration: expiration,
        priority: priority,
        apnsID: nil,
        topic: topic,
        collapseID: nil
      )
    )

    if let apnsUniqueID = result.apnsUniqueID {
      logger.info("Sent issue report accepted notification to user \(user.id?.value ?? ""): \(apnsUniqueID)")
    }
  }
}

extension Request {
  var notificationService: NotificationService {
    NotificationService(application: application)
  }
}

extension Application {
  var notificationService: NotificationService {
    NotificationService(application: self)
  }
}
