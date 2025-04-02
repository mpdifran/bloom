//
//  AdminUserDatabaseService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-01-22.
//

import Foundation
import Vapor
import Fluent
import BloomModel
import SignInWithApple

struct AdminUserDatabaseService {
  let db: any Database
}

extension AdminUserDatabaseService {

  func fetchUser(for userID: UserIdentifier) async throws -> AdminUser? {
    try await AdminUser.query(on: db)
      .filter(\.$id == userID)
      .first()
  }

  func fetchOrCreateUser(for userID: UserIdentifier) async throws -> AdminUser {
    if let user = try await fetchUser(for: userID) {
      return user
    }
    return AdminUser(id: userID)
  }

  @discardableResult
  func storeTokens(
    userID: UserIdentifier,
    tokenResponse: AppleTokenResponse
  ) async throws -> AdminUser {
    let user = try await fetchOrCreateUser(for: userID)

    user.accessToken = tokenResponse.accessToken
    user.refreshToken = tokenResponse.refreshToken
    user.idToken = tokenResponse.idToken

    let expiryDate = Date().addingTimeInterval(tokenResponse.expiresIn)
    user.accessTokenExpiry = expiryDate

    try await user.save(on: db)
    return user
  }

  @discardableResult
  func storeUserDetails(
    userID: UserIdentifier,
    email: String?,
    givenName: String?,
    familyName: String?,
    rawUserDetectionStatus: String?
  ) async throws -> AdminUser {
    let user = try await fetchOrCreateUser(for: userID)

    email.map { user.email = $0 }
    givenName.map { user.givenName = $0 }
    familyName.map { user.familyName = $0 }
    rawUserDetectionStatus.map { user.rawUserDetectionStatus = $0 }

    try await user.save(on: db)
    return user
  }

  func logout(auth: Request.Authentication) async throws -> Response {
    let authToken = try auth.require(AdminUserToken.self)
    auth.logout(AdminUser.self)
    try await authToken.delete(on: db)
    return Response(status: .ok)
  }
}
