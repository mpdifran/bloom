//
//  OnboardingLoginViewModel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-25.
//

import SwiftUI
import AuthenticationServices
import BloomModel

extension OnboardingLoginView.ViewModel {
    enum AuthError: LocalizedError {
        case invalidCredentials

        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return String(
                    localized: "The provided credentials are invalid",
                    comment: "Error shown when Sign in with Apple returns credentials Bloom can't use."
                )
            }
        }
    }
}

extension OnboardingLoginView {
  @MainActor @Observable
  final class ViewModel {
    var isAuthenticating = false
  }
}

extension OnboardingLoginView.ViewModel {

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

    let userDetectionStatus: AuthenticationRequest.UserDetectionStatus
    switch credential.realUserStatus {
    case .unsupported: userDetectionStatus = .unsupported
    case .unknown: userDetectionStatus = .unknown
    case .likelyReal: userDetectionStatus = .likelyReal
    @unknown default: userDetectionStatus = .newCase
    }

    let userIdentifier = UserIdentifier(credential.user)
    let authRequest = AuthenticationRequest(
      userIdentifier: userIdentifier,
      identityToken: identityToken,
      authorizationCode: authCode,
      email: credential.email,
      givenName: credential.fullName?.givenName,
      familyName: credential.fullName?.familyName,
      userDetectionStatus: userDetectionStatus,
      appUserID: UserID.value
    )

    try await UserController.shared.authenticate(
      userIdentifier: userIdentifier,
      authRequest: authRequest
    )
  }
}
