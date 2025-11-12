//
//  UserController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-12-01.
//

import Foundation
import Vapor
import SignInWithApple
import BloomModel

struct UserController { }

extension UserController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1") {
      $0.group("auth") {
        $0.post("sign-in", use: signIn)
      }

      $0.auth(using: UserToken.self) {
        $0.group("user") {
          $0.post("identify", use: identify)
          $0.post("register-device-token", use: registerDeviceToken)
          $0.post("morning-notification-time", use: updateMorningNotificationTime)
          $0.post("test-push-notification", use: testPushNotification)
          $0.post("consent", use: updateConsent)
          $0.get("logout", use: logout)
          $0.get("delete-account", use: deleteAccount)
        }
      }
    }

    routes.group("webhook") {
      $0.post("apple", use: handleWebhook)
    }
  }
}

private extension UserController {

  @Sendable
  func signIn(_ request: Request) async throws -> AuthenticationResponse {
    let auth = try request.content.decode(AuthenticationRequest.self)

    let details = AppleTokenGenerationDetails(
      teamIdentifier: request.application.appleTeamID,
      appIdentifier: request.application.bloomAppBundleID,
      identityToken: auth.identityToken,
      authorizationCode: auth.authorizationCode,
      privateKey: try request.application.createBloomSiwAPrivateKey()
    )

    let appleTokens = try await request.signInWithApple.generateAppleTokens(details: details)

    let user = try await request.userDatabaseService.storeTokens(
      userID: auth.userIdentifier,
      tokenResponse: appleTokens
    )

    // Store user details
    try await request.userDatabaseService.storeUserDetails(
      userID: auth.userIdentifier,
      email: auth.email,
      givenName: auth.givenName,
      familyName: auth.familyName,
      rawUserDetectionStatus: auth.userDetectionStatus.rawValue,
      appUserID: auth.appUserID
    )

    let userToken = try user.generateToken()
    try await userToken.save(on: request.db)

    let identity = AuthIdentifyResponse(
      email: user.email,
      givenName: user.givenName,
      familyName: user.familyName
    )

    return AuthenticationResponse(
      authToken: AuthToken(userToken.value),
      identity: identity
    )
  }

  @Sendable
  func identify(_ request: Request) async throws -> AuthIdentifyResponse {
    let user = try request.auth.require(User.self)
    let identityRequest = try request.content.decode(AuthIdentifyRequest.self)

    try await request.userDatabaseService.storeAppUserID(
      user: user,
      appUserID: identityRequest.appUserID,
      appVersion: identityRequest.appVersion
    )

    return AuthIdentifyResponse(
      email: user.email,
      givenName: user.givenName,
      familyName: user.familyName
    )
  }

  @Sendable
  func registerDeviceToken(_ request: Request) async throws -> Response {
    let user = try request.auth.require(User.self)
    let body = try request.content.decode(RegisterUserPushNotificationTokenRequest.self)

    user.apnsDeviceToken = body.deviceToken
    try await user.save(on: request.db)

    return Response(status: .ok)
  }

  @Sendable
  func updateMorningNotificationTime(_ request: Request) async throws -> Response {
    let user = try request.auth.require(User.self)
    let body = try request.content.decode(UpdateMorningNotificationTimeRequest.self)

    // Validate timezone
    guard let userTimeZone = TimeZone(identifier: body.timeZone) else {
      throw Abort(.badRequest, reason: "Invalid timezone identifier")
    }

    // Validate hour and minute
    guard (0...23).contains(body.hour) else {
      throw Abort(.badRequest, reason: "Hour must be between 0 and 23")
    }
    guard (0...59).contains(body.minute) else {
      throw Abort(.badRequest, reason: "Minute must be between 0 and 59")
    }

    // Round minute to nearest 5
    let roundedMinute = Int((Double(body.minute) / 5.0).rounded()) * 5

    // Convert user's local time to UTC
    var userCalendar = Calendar.current
    userCalendar.timeZone = userTimeZone

    // Create date components for today at the specified time
    let now = Date()
    var components = userCalendar.dateComponents([.year, .month, .day], from: now)
    components.hour = body.hour
    components.minute = roundedMinute

    // Get the date in user's timezone
    guard let userDate = userCalendar.date(from: components) else {
      throw Abort(.internalServerError, reason: "Failed to create date from components")
    }

    // Convert to UTC components
    var utcCalendar = Calendar.current
    utcCalendar.timeZone = TimeZone(identifier: "UTC")!
    let utcComponents = utcCalendar.dateComponents([.hour, .minute], from: userDate)

    // Update user preferences with UTC time
    user.morningNotificationHour = utcComponents.hour
    user.morningNotificationMinute = utcComponents.minute
    try await user.save(on: request.db)

    return Response(status: .ok)
  }

  @Sendable
  func testPushNotification(_ request: Request) async throws -> Response {
    let user = try request.auth.require(User.self)

    // Ensure user has a registered device token
    guard let deviceToken = user.apnsDeviceToken else {
      throw Abort(.badRequest, reason: "No device token registered. Please ensure push notifications are enabled.")
    }

    // Send test notification
    try await request.notificationService.sendTestNotification(to: user, deviceToken: deviceToken)

    request.logger.info("Test push notification sent to user \(user.id?.value ?? "")")

    return Response(status: .ok)
  }

  @Sendable
  func updateConsent(_ request: Request) async throws -> ConsentResponse {
    let user = try request.auth.require(User.self)
    let body = try request.content.decode(UpdateConsentRequest.self)

    var hasChanges = false

    // Update health data consent if provided
    if let healthDataConsent = body.healthDataConsent {
      let newValue: Date? = healthDataConsent ? Date() : nil
      let currentHasConsent = user.healthDataConsentGrantedAt != nil

      if healthDataConsent != currentHasConsent {
        user.healthDataConsentGrantedAt = newValue
        hasChanges = true
      }
    }

    // Update external processing consent if provided
    if let externalProcessingConsent = body.externalProcessingConsent {
      let newValue: Date? = externalProcessingConsent ? Date() : nil
      let currentHasConsent = user.externalProcessingConsentGrantedAt != nil

      if externalProcessingConsent != currentHasConsent {
        user.externalProcessingConsentGrantedAt = newValue
        hasChanges = true
      }
    }

    // Only save if there were changes
    if hasChanges {
      try await user.save(on: request.db)
    }

    // Return current consent state
    return ConsentResponse(
      hasHealthDataConsent: user.healthDataConsentGrantedAt != nil,
      hasExternalProcessingConsent: user.externalProcessingConsentGrantedAt != nil
    )
  }

  @Sendable
  func logout(_ request: Request) async throws -> Response {
    try await request.userDatabaseService.logout(auth: request.auth)
  }

  @Sendable
  func deleteAccount(_ request: Request) async throws -> Response {
    try await request.userDatabaseService.deleteAccount(auth: request.auth)
  }

  @Sendable
  func handleWebhook(_ request: Request) async throws -> Response {
    request.logger.info("Received webhook from Sign In With Apple")

    return Response(status: .ok)
  }
}
