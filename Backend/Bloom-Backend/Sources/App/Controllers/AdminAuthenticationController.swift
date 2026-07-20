//
//  AdminAuthenticationController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-01-22.
//

import Foundation
import Vapor
import SignInWithApple
@preconcurrency import JWT
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

    // Bind the session to the identity proven by the verified Apple token, and
    // capture the verified email. Apple only includes `email` on the first
    // authorization, so it may be nil on re-login (we then trust the email
    // already persisted from a prior verified token). Both values are extracted
    // inside the closure so the non-Sendable token never crosses an await.
    let (verifiedSubject, verifiedEmail): (String, String?) = try await {
      let token = try await request.jwt.apple.verify(
        auth.identityToken,
        applicationIdentifier: request.application.gardenerAppBundleID
      ).get()
      return (token.subject.value, token.email)
    }()

    guard verifiedSubject == auth.userIdentifier.value else {
      throw Abort(.unauthorized, reason: "Identity token does not match the provided user identifier")
    }

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

    // Store user details. Only ever persist the VERIFIED email (never the
    // client-supplied one), so a client cannot poison its row with an
    // allowlisted email to escalate to admin.
    try await request.adminUserDatabaseService.storeUserDetails(
      userID: auth.userIdentifier,
      email: verifiedEmail,
      givenName: auth.givenName,
      familyName: auth.familyName,
      rawUserDetectionStatus: auth.userDetectionStatus.rawValue
    )

    // Only let approved people sign in. Compare the verified email (or the
    // previously-verified stored email) against the allowlist, case-insensitively.
    // Fail closed if the allowlist is unset/empty.
    let emailAllowlist = request.application.adminEmailAllowList()
    guard
      let email = (verifiedEmail ?? user.email)?.lowercased(),
      !emailAllowlist.isEmpty,
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
