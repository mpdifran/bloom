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

struct UserDatabaseService { }

extension UserDatabaseService {

  func fetchUser(_ request: Request, for userID: UserIdentifier) async throws -> User? {
    try await User.query(on: request.db)
      .filter(\.$id == userID)
      .first()
  }

  func fetchOrCreateUser(_ request: Request, for userID: UserIdentifier) async throws -> User {
    if let user = try await fetchUser(request, for: userID) {
      return user
    }
    return User(id: userID)
  }

  @discardableResult
  func storeTokens(
    _ request: Request,
    userID: UserIdentifier,
    tokenResponse: AppleTokenResponse
  ) async throws -> User {
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
    rawUserDetectionStatus: String?,
    appUserID: String?
  ) async throws -> User {
    let user = try await fetchOrCreateUser(request, for: userID)

    email.map { user.email = $0 }
    givenName.map { user.givenName = $0 }
    familyName.map { user.familyName = $0 }
    rawUserDetectionStatus.map { user.rawUserDetectionStatus = $0 }
    appUserID.map { user.appUserID = $0 }

    try await user.save(on: request.db)
    return user
  }

  @discardableResult
  func storeAppUserID(
    _ request: Request,
    appUserID: String,
    appVersion: String?
  ) async throws -> User {
    let user = try await fetchAuthUser(request)

    user.appUserID = appUserID
    if let appVersion {
      user.appVersion = appVersion
    }

    try await user.save(on: request.db)
    return user
  }

  func fetchAuthUser(_ request: Request) async throws -> User {
    let authToken = try request.auth.require(UserToken.self)

    guard let user = try await User.find(authToken.$user.id, on: request.db) else {
      throw Abort(.notFound, reason: "User not found")
    }

    return user
  }

  func logout(_ request: Request) async throws -> Response {
    let authToken = try request.auth.require(UserToken.self)
    request.auth.logout(User.self)
    try await authToken.delete(on: request.db)
    return Response(status: .ok)
  }

  func deleteAccount(_ request: Request) async throws -> Response {
    let authToken = try request.auth.require(UserToken.self)

    guard let user = try await User.find(authToken.$user.id, on: request.db) else {
      throw Abort(.notFound, reason: "User not found")
    }

    try await authToken.delete(on: request.db)
    request.auth.logout(User.self)
    try await user.delete(on: request.db)

    return Response(status: .ok)
  }
}
