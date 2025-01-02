//
//  LoginViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-19.
//

import SwiftUI
import AuthenticationServices
import BloomModel

extension LoginView.ViewModel {
    enum AuthError: LocalizedError {
        case invalidCredentials

        var errorDescription: String? {
            switch self {
            case .invalidCredentials: return "The provided credentials are invalid"
            }
        }
    }
}

extension LoginView {

  @Observable @MainActor
  final class ViewModel {
    var isAuthenticating = false
  }
}

extension LoginView.ViewModel {

  func authenticate(using credential: ASAuthorizationAppleIDCredential) async throws {
    isAuthenticating = true

    defer {
      isAuthenticating = false
    }

    guard
      let identityTokenData = credential.identityToken,
      let authCodeData = credential.authorizationCode,
      let identityToken = String(data: identityTokenData, encoding: .utf8),
      let authCode = String(data: authCodeData, encoding: .utf8)
    else {
      throw AuthError.invalidCredentials
    }

    let userIdentifier = UserIdentifier(credential.user)
    let authRequest = AuthenticationRequest(
      userIdentifier: userIdentifier,
      identityToken: identityToken,
      authorizationCode: authCode
    )

    let authResponse = try await NetworkRequester.shared.authenticate(request: authRequest)

    await UserController.shared.authenticate(
      userIdentifier: userIdentifier,
      authToken: authResponse.authToken
    )
  }
}
