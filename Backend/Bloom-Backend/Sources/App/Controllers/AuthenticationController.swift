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
    routes.group("v1") { v1 in
      routes.group("auth") { auth in
        auth.post("sign-in", use: signIn)
      }

      routes.group(UserToken.guardMiddleware()) { tokenProtected in
        tokenProtected.group("user") { user in
          user.get("logout", use: logout)
        }
      }
    }

    routes.group("webhook") { webhook in
      webhook.post("apple", use: handleWebhook)
    }
  }
}

private extension AuthenticationController {

  @Sendable
  func signIn(_ request: Request) async throws -> AuthenticationResponse {
    let auth = try request.content.decode(AuthenticationRequest.self)

    let details = AppleTokenGenerationDetails(
      teamIdentifier: request.application.appleTeamID,
      appIdentifier: request.application.appBundleID,
      identityToken: auth.identityToken,
      authorizationCode: auth.authorizationCode,
      privateKey: try request.application.createSIWAPrivateKey()
    )

    let appleTokens = try await request.signInWithApple.generateAppleTokens(details: details)

    let user = try await userService.storeTokens(
      request,
      userID: auth.userIdentifier,
      tokenResponse: appleTokens
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
  func handleWebhook(_ request: Request) async throws -> Response {
    request.logger.info("Received webhook from Sign In With Apple")

    return Response(status: .ok)
  }
}
