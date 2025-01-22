//
//  AdminUser.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-01-22.
//

import Foundation
import Vapor
import Fluent
import BloomModel

final class AdminUser: Model, Content, @unchecked Sendable {
  static let schema = "admin_users"

  @ID(custom: "id", generatedBy: .user)
  var id: UserIdentifier?

  @Field(key: "email")
  var email: String?

  @Field(key: "given_name")
  var givenName: String?

  @Field(key: "family_name")
  var familyName: String?

  @Field(key: "user_detection_status")
  var rawUserDetectionStatus: String?

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

  init() { }

  init(id: UserIdentifier,
       email: String? = nil,
       givenName: String? = nil,
       familyName: String? = nil,
       rawUserDetectionStatus: String? = nil,
       accessToken: String? = nil,
       refreshToken: String? = nil,
       idToken: String? = nil,
       accessTokenExpiry: Date? = nil,
       lastActiveAt: Date = Date()) {
    self.id = id
    self.email = email
    self.givenName = givenName
    self.familyName = familyName
    self.rawUserDetectionStatus = rawUserDetectionStatus
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    self.idToken = idToken
    self.accessTokenExpiry = accessTokenExpiry
  }
}

extension AdminUser: Authenticatable { }

extension AdminUser {

  var userDetectionStatus: AuthenticationRequest.UserDetectionStatus? {
    AuthenticationRequest.UserDetectionStatus(rawValue: rawUserDetectionStatus ?? "")
  }

  func generateToken() throws -> AdminUserToken {
    AdminUserToken(
      value: [UInt8].random(count: 32).base64,
      userID: try self.requireID()
    )
  }
}
