//
//  UserController.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-19.
//

import BloomModel
import Valet
import TelemetryDeck

private extension String {
  static let authenticatedUserIdentifierKey = "user_identifier"
  static let authTokenKey = "auth_token"
}

final actor UserController {

  @AsyncStreamable var isAuthenticated: Bool = false

  /// An identifier for the Sign in with Apple user. This may change if the account is unlinked and re-linked.
  var authenticatedUserIdentifier: String?

  /// The auth token for the authenticated user.
  var authToken: AuthToken?

  private let valet = Valet.iCloudValet(
    with: Identifier(nonEmpty: "UserController")!,
    accessibility: .afterFirstUnlock
  )

  init() {
    do {
      let rawAuthToken = try valet.string(forKey: .authTokenKey)
      self.authToken = AuthToken(rawAuthToken)
    } catch { }

    self._isAuthenticated.update(authToken != nil)
  }
}

extension UserController {

  func authenticate(userIdentifier: String, authToken: AuthToken) {
    self.authenticatedUserIdentifier = userIdentifier
    self.authToken = authToken

    storeAuthenticatedUserIdentifier()
    storeAuthToken()

    self.isAuthenticated = self.authToken != nil
  }

  func logout() {
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
        try valet.setString(authenticatedUserIdentifier, forKey: .authenticatedUserIdentifierKey)
      } else {
        try valet.removeObject(forKey: .authenticatedUserIdentifierKey)
      }
    } catch {
      TelemetryDeck.errorOccurred(
        id: "UserController.storeAuthenticatedUserIdentifier",
        category: .thrownException,
        message: error.localizedDescription
      )
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
      TelemetryDeck.errorOccurred(
        id: "UserController.storeAuthToken",
        category: .thrownException,
        message: error.localizedDescription
      )
      print(error)
    }
  }
}
