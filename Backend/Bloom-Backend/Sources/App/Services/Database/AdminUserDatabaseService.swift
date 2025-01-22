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

struct AdminUserDatabaseService { }

extension AdminUserDatabaseService {

  func fetchUser(_ request: Request, for userID: UserIdentifier) async throws -> AdminUser? {
    try await AdminUser.query(on: request.db)
      .filter(\.$id == userID)
      .first()
  }

  func fetchOrCreateUser(_ request: Request, for userID: UserIdentifier) async throws -> AdminUser {
    if let user = try await fetchUser(request, for: userID) {
      return user
    }
    return AdminUser(id: userID)
  }

  @discardableResult
  func storeTokens(
    _ request: Request,
    userID: UserIdentifier,
    tokenResponse: AppleTokenResponse
  ) async throws -> AdminUser {
    let user = try await fetchOrCreateUser(request, for: userID)

    user.accessToken = tokenResponse.accessToken
    user.refreshToken = tokenResponse.refreshToken
    user.idToken = tokenResponse.idToken

    let expiryDate = Date().addingTimeInterval(tokenResponse.expiresIn)
    user.accessTokenExpiry = expiryDate

    try await user.save(on: request.db)
    return user
  }

  @discardableResult
  func storeUserDetails(
    _ request: Request,
    userID: UserIdentifier,
    email: String?,
    givenName: String?,
    familyName: String?,
    rawUserDetectionStatus: String?
  ) async throws -> AdminUser {
    let user = try await fetchOrCreateUser(request, for: userID)

    email.map { user.email = $0 }
    givenName.map { user.givenName = $0 }
    familyName.map { user.familyName = $0 }
    rawUserDetectionStatus.map { user.rawUserDetectionStatus = $0 }

    try await user.save(on: request.db)
    return user
  }

  func logout(_ request: Request) async throws -> Response {
    let authToken = try request.auth.require(AdminUserToken.self)
    request.auth.logout(AdminUser.self)
    try await authToken.delete(on: request.db)
    return Response(status: .ok)
  }
}
