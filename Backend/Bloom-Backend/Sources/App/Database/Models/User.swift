//
//  User.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-12-22.
//

import Foundation
import Vapor
import Fluent
import BloomModel

final class User: Model, Content, @unchecked Sendable {
  static let schema = "users"

  @ID(custom: "id", generatedBy: .user)
  var id: UserIdentifier?

  @Field(key: "app_user_id")
  var appUserID: String?

  @Field(key: "email")
  var email: String?

  @Field(key: "given_name")
  var givenName: String?

  @Field(key: "family_name")
  var familyName: String?

  @Field(key: "app_version")
  var appVersion: String?

  @Field(key: "user_detection_status")
  var rawUserDetectionStatus: String?

  @Field(key: "health_coach_thread_id")
  var healthCoachThreadID: String?

  @Field(key: "health_goal_setter_thread_id")
  var healthGoalSetterThreadID: String?

  @Field(key: "apns_device_token")
  var apnsDeviceToken: String?

  @Field(key: "access_token")
  var accessToken: String?

  @Field(key: "refresh_token")
  var refreshToken: String?

  @Field(key: "id_token")
  var idToken: String?

  @Field(key: "access_token_expiry")
  var accessTokenExpiry: Date?

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  @Children(for: \.$user)
  var foodItemIssueReports: [FoodItemIssueReport]

  init() { }

  init(
    id: UserIdentifier,
    email: String? = nil,
    givenName: String? = nil,
    familyName: String? = nil,
    appVersion: String? = nil,
    rawUserDetectionStatus: String? = nil,
    healthCoachThreadID: String? = nil,
    healthGoalSetterThreadID: String? = nil,
    apnsDeviceToken: String? = nil,
    accessToken: String? = nil,
    refreshToken: String? = nil,
    idToken: String? = nil,
    accessTokenExpiry: Date? = nil,
    lastActiveAt: Date = Date()
  ) {
    self.id = id
    self.email = email
    self.givenName = givenName
    self.familyName = familyName
    self.appVersion = appVersion
    self.rawUserDetectionStatus = rawUserDetectionStatus
    self.healthCoachThreadID = healthCoachThreadID
    self.healthGoalSetterThreadID = healthGoalSetterThreadID
    self.apnsDeviceToken = apnsDeviceToken
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    self.idToken = idToken
    self.accessTokenExpiry = accessTokenExpiry
  }
}

extension User: Authenticatable { }

extension User {

  var userDetectionStatus: AuthenticationRequest.UserDetectionStatus? {
    AuthenticationRequest.UserDetectionStatus(rawValue: rawUserDetectionStatus ?? "")
  }

  func generateToken() throws -> UserToken {
    UserToken(
      value: [UInt8].random(count: 32).base64,
      userID: try self.requireID()
    )
  }
}
