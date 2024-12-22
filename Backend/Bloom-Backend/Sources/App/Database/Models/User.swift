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
       accessToken: String? = nil,
       refreshToken: String? = nil,
       idToken: String? = nil,
       accessTokenExpiry: Date? = nil,
       lastActiveAt: Date = Date()) {
    self.id = id
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    self.idToken = idToken
    self.accessTokenExpiry = accessTokenExpiry
  }
}

extension User: Authenticatable { }

extension User {

  func generateToken() throws -> UserToken {
    UserToken(value: [UInt8].random(count: 32).base64,
              userID: try self.requireID())
  }
}
