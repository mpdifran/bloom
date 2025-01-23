//
//  UserController.swift
//  Gardener
//
//  Created by Mark DiFranco on 2025-01-22.
//

import BloomModel
import Valet
import AuthenticationServices

private extension String {
  static let authenticatedUserIdentifierKey = "gardener.user_identifier"
  static let authTokenKey = "gardener.auth_token"
}

final actor UserController {
  static let shared = UserController()

  @AsyncStreamable var isAuthenticated: Bool = false

  /// An identifier for the Sign in with Apple user. This may change if the account is unlinked and re-linked.
  var authenticatedUserIdentifier: UserIdentifier?

  /// The auth token for the authenticated user.
  var authToken: AuthToken?

  private let valet = Valet.iCloudValet(
    with: Identifier(nonEmpty: "UserController")!,
    accessibility: .afterFirstUnlock
  )

  private init() {
    do {
      let rawUserIdentifier = try valet.string(forKey: .authenticatedUserIdentifierKey)
      self.authenticatedUserIdentifier = UserIdentifier(rawUserIdentifier)
    } catch { }
    do {
      let rawAuthToken = try valet.string(forKey: .authTokenKey)
      self.authToken = AuthToken(rawAuthToken)
    } catch { }

    self._isAuthenticated.update(authToken != nil)
  }
}

extension UserController {

  func verifyAuthentication() async throws {
    guard let userIdentifier = authenticatedUserIdentifier else { return }

    let provider = ASAuthorizationAppleIDProvider()

    do {
      let state = try await provider.credentialState(forUserID: userIdentifier.value)

      switch state {
      case .authorized:
        // We're good
        break
      case .revoked, .notFound:
        try await logout()
      case .transferred:
        // Refresh user identifier when transferring ownership of app
        break
      @unknown default:
          break
      }
    } catch {
      print(error)
    }
  }

  func authenticate(userIdentifier: UserIdentifier, authRequest: AuthenticationRequest) async throws {
    let authResponse = try await NetworkStack.shared.login(request: authRequest)

    self.authenticatedUserIdentifier = userIdentifier
    self.authToken = authResponse.authToken

    storeAuthenticatedUserIdentifier()
    storeAuthToken()

    self.isAuthenticated = self.authToken != nil
  }

  func logout() async throws {
    try await NetworkStack.shared.logout()

    authenticatedUserIdentifier = nil
    authToken = nil

    storeAuthenticatedUserIdentifier()
    storeAuthToken()

    self.isAuthenticated = self.authToken != nil
  }
}

private extension UserController {

  func storeAuthenticatedUserIdentifier() {
    do {
      if let authenticatedUserIdentifier {
        try valet.setString(authenticatedUserIdentifier.value, forKey: .authenticatedUserIdentifierKey)
      } else {
        try valet.removeObject(forKey: .authenticatedUserIdentifierKey)
      }
    } catch {
      print(error)
    }
  }

  func storeAuthToken() {
    do {
      if let authToken {
        try valet.setString(authToken.value, forKey: .authTokenKey)
      } else {
        try valet.removeObject(forKey: .authTokenKey)
      }
    } catch {
      print(error)
    }
  }
}
