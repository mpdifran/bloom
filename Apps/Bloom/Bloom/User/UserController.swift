//
//  UserController.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-19.
//

import SwiftUI
import BloomModel
import Valet
import TelemetryDeck
import RevenueCat
import AuthenticationServices

private extension String {
  static let authenticatedUserIdentifierKey = "user_identifier"
  static let authTokenKey = "auth_token"
}

final actor UserController {
  static let shared = UserController()

  @AsyncStreamable var isAuthenticated: Bool = false

  @AppStorage("UserController.email", store: .group) private var email: String?
  @AppStorage("UserController.givenName", store: .group) private var givenName: String?
  @AppStorage("UserController.familyName", store: .group) private var familyName: String?

  private var lastIdentifyDate: Date? {
    didSet { UserDefaults.group.set(lastIdentifyDate, forKey: "UserController.lastIdentifyDate") }
  }

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

    if let lastIdentifyDate = UserDefaults.group.object(forKey: "UserController.lastIdentifyDate") as? Date {
      self.lastIdentifyDate = lastIdentifyDate
    }

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
      TelemetryDeck.errorOccurred(
        id: "UserController.verifyAuthentication",
        category: .thrownException,
        message: error.localizedDescription
      )
    }
  }

  func identify() async {
    do {
      if email != nil || givenName != nil || familyName != nil {
        if let lastIdentifyDate, lastIdentifyDate.timeIntervalSinceNow > -7 * 24 * 60 * 60 {
          return // We've already checked recently.
        }
      }

      let requestBody = AuthIdentifyRequest(appUserID: UserID.value)
      let response = try await NetworkRequester.shared.identify(request: requestBody)

      self.email = response.email
      self.givenName = response.givenName
      self.familyName = response.familyName
      self.lastIdentifyDate = .now
      self.registerDetailsWithRevenueCat()
    } catch {
      print(error) // Swallow the error
    }
  }

  func authenticate(userIdentifier: UserIdentifier, authRequest: AuthenticationRequest) async throws {
    let authResponse = try await NetworkRequester.shared.authenticate(request: authRequest)

    self.email = authResponse.identity.email
    self.givenName = authResponse.identity.givenName
    self.familyName = authResponse.identity.familyName
    self.lastIdentifyDate = .now
    self.registerDetailsWithRevenueCat()

    self.authenticatedUserIdentifier = userIdentifier
    self.authToken = authResponse.authToken

    storeAuthenticatedUserIdentifier()
    storeAuthToken()

    self.isAuthenticated = self.authToken != nil
  }

  func logout() async throws {
    try await NetworkRequester.shared.signOut()

    authenticatedUserIdentifier = nil
    authToken = nil
    email = nil
    givenName = nil
    familyName = nil
    lastIdentifyDate = nil

    registerDetailsWithRevenueCat()
    storeAuthenticatedUserIdentifier()
    storeAuthToken()

    self.isAuthenticated = self.authToken != nil
  }

  func deleteAccount() async throws {
    try await NetworkRequester.shared.deleteAccount()

    authenticatedUserIdentifier = nil
    authToken = nil
    email = nil
    givenName = nil
    familyName = nil
    lastIdentifyDate = nil

    registerDetailsWithRevenueCat()
    storeAuthenticatedUserIdentifier()
    storeAuthToken()

    self.isAuthenticated = self.authToken != nil
  }
}

private extension UserController {

  func registerDetailsWithRevenueCat() {
    var attributes: [String: String] = [:]

    let name = [givenName, familyName].compactMap({ $0 }).joined(separator: " ")
    attributes["$displayName"] = name
    attributes["$email"] = email ?? ""

    Purchases.shared.attribution.setAttributes(attributes)
  }

  func storeAuthenticatedUserIdentifier() {
    do {
      if let authenticatedUserIdentifier {
        try valet.setString(authenticatedUserIdentifier.value, forKey: .authenticatedUserIdentifierKey)
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
