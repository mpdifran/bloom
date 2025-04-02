//
//  UserDatabaseService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-12-22.
//

import Foundation
import Vapor
import Fluent
import BloomModel
import SignInWithApple

struct UserDatabaseService {
  let db: any Database
}

extension UserDatabaseService {

  func fetchUser(for userID: UserIdentifier) async throws -> User? {
    try await User.query(on: db)
      .filter(\.$id == userID)
      .first()
  }

  func fetchOrCreateUser(for userID: UserIdentifier) async throws -> User {
    if let user = try await fetchUser(for: userID) {
      return user
    }
    return User(id: userID)
  }

  @discardableResult
  func storeTokens(
    userID: UserIdentifier,
    tokenResponse: AppleTokenResponse
  ) async throws -> User {
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
    rawUserDetectionStatus: String?,
    appUserID: String?
  ) async throws -> User {
    let user = try await fetchOrCreateUser(for: userID)

    email.map { user.email = $0 }
    givenName.map { user.givenName = $0 }
    familyName.map { user.familyName = $0 }
    rawUserDetectionStatus.map { user.rawUserDetectionStatus = $0 }
    appUserID.map { user.appUserID = $0 }

    try await user.save(on: db)
    return user
  }

  func storeAppUserID(
    user: User,
    appUserID: String,
    appVersion: String?
  ) async throws {
    user.appUserID = appUserID
    if let appVersion {
      user.appVersion = appVersion
    }
    try await user.save(on: db)
  }

  func logout(auth: Request.Authentication) async throws -> Response {
    let authToken = try auth.require(UserToken.self)
    auth.logout(User.self)
    try await authToken.delete(on: db)
    return Response(status: .ok)
  }

  func deleteAccount(auth: Request.Authentication) async throws -> Response {
    let authToken = try auth.require(UserToken.self)

    guard let user = try await User.find(authToken.$user.id, on: db) else {
      throw Abort(.notFound, reason: "User not found")
    }

    try await authToken.delete(on: db)
    auth.logout(User.self)
    try await user.delete(on: db)

    return Response(status: .ok)
  }
}
