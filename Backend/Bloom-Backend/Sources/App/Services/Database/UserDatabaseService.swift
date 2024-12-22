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

  func storeTokens(_ request: Request, userID: UserIdentifier, tokenResponse: AppleTokenResponse) async throws -> User {
    let user = User(id: userID)

    user.accessToken = tokenResponse.accessToken
    user.refreshToken = tokenResponse.refreshToken
    user.idToken = tokenResponse.idToken

    let expiryDate = Date().addingTimeInterval(tokenResponse.expiresIn)
    user.accessTokenExpiry = expiryDate

    try await user.save(on: request.db) // This should upsert according to the docs
    return user
  }

  func logout(_ request: Request) async throws -> Response {
    let authToken = try request.auth.require(UserToken.self)
    request.auth.logout(User.self)
    try await authToken.delete(on: request.db)
    return Response(status: .ok)
  }
}
