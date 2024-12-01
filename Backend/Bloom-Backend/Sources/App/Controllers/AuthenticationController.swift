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

struct AuthenticationController { }

extension AuthenticationController: RouteCollection {

    func boot(routes: any RoutesBuilder) throws {
        routes.group("v1", "auth") { auth in
            auth.post("sign-in", use: signIn)
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

        // TODO: Store tokens in database

        return AuthenticationResponse(authToken: AuthToken("TODO: Implement"))
    }
}
