//
//  AuthenticationController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-12-01.
//

import Foundation
import Vapor
import SignInWithApple
import BloomModel

struct AuthenticationController {
  private let userService = UserDatabaseService()
}

extension AuthenticationController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1") {
      $0.group("auth") {
        $0.post("sign-in", use: signIn)
      }

      $0.auth(using: UserToken.self) {
        $0.group("user") {
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

private extension AuthenticationController {

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

    let user = try await userService.storeTokens(
      request,
      userID: auth.userIdentifier,
      tokenResponse: appleTokens
    )

    // Store user details
    try await userService.storeUserDetails(
      request,
      userID: auth.userIdentifier,
      email: auth.email,
      givenName: auth.givenName,
      familyName: auth.familyName,
      rawUserDetectionStatus: auth.userDetectionStatus.rawValue
    )

    let userToken = try user.generateToken()
    try await userToken.save(on: request.db)

    return AuthenticationResponse(authToken: AuthToken(userToken.value))
  }

  @Sendable
  func logout(_ request: Request) async throws -> Response {
    try await userService.logout(request)
  }

  @Sendable
  func deleteAccount(_ request: Request) async throws -> Response {
    try await userService.deleteAccount(request)
  }

  @Sendable
  func handleWebhook(_ request: Request) async throws -> Response {
    request.logger.info("Received webhook from Sign In With Apple")

    return Response(status: .ok)
  }
}
