//
//  AdminAuthenticationController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-01-22.
//

import Foundation
import Vapor
import SignInWithApple
import BloomModel

struct AdminAuthenticationController { }

extension AdminAuthenticationController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1", "admin") {
      $0.group("auth") {
        $0.post("sign-in", use: signIn)
      }

      $0.auth(using: AdminUserToken.self) {
        $0.group("user") {
          $0.get("logout", use: logout)
        }
      }
    }
  }
}

private extension AdminAuthenticationController {

  @Sendable
  func signIn(_ request: Request) async throws -> AuthenticationResponse {
    let auth = try request.content.decode(AuthenticationRequest.self)

    let details = AppleTokenGenerationDetails(
      teamIdentifier: request.application.gardenerAppleTeamID,
      appIdentifier: request.application.gardenerAppBundleID,
      identityToken: auth.identityToken,
      authorizationCode: auth.authorizationCode,
      privateKey: try request.application.createGardenerSiwAPrivateKey()
    )

    let appleTokens = try await request.signInWithApple.generateAppleTokens(details: details)

    let user = try await request.adminUserDatabaseService.storeTokens(
      userID: auth.userIdentifier,
      tokenResponse: appleTokens
    )

    // Store user details
    try await request.adminUserDatabaseService.storeUserDetails(
      userID: auth.userIdentifier,
      email: auth.email,
      givenName: auth.givenName,
      familyName: auth.familyName,
      rawUserDetectionStatus: auth.userDetectionStatus.rawValue
    )

    // Only let approved people sign in.
    let emailAllowlist = request.application.adminEmailAllowList()
    guard
      let email = user.email ?? auth.email,
      emailAllowlist.contains(email)
    else {
      throw Abort(.forbidden)
    }

    // Create a token for auth
    let userToken = try user.generateToken()
    try await userToken.save(on: request.db)

    return AuthenticationResponse(
      authToken: AuthToken(userToken.value),
      identity: .init(
        email: auth.email,
        givenName: auth.givenName,
        familyName: auth.familyName
      )
    )
  }

  @Sendable
  func logout(_ request: Request) async throws -> Response {
    try await request.adminUserDatabaseService.logout(auth: request.auth)
  }
}
