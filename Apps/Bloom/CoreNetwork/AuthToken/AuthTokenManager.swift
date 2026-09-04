//
//  AuthTokenManager.swift
//  CoreNetwork
//
//  Created by Claude on 2025-10-16.
//

import Foundation
import Combine
import BloomModel
import BloomFoundation
import Valet

private extension String {
  static let authenticatedUserIdentifierKey = "user_identifier"
  static let authTokenKey = "auth_token"
}

#if targetEnvironment(simulator)
// Simulator-specific UserDefaults keys for development purposes
private extension String {
  static let simulatorUserIdentifierKey = "simulator_user_identifier"
  static let simulatorAuthTokenKey = "simulator_auth_token"
}
#endif

@MainActor
public final class AuthTokenManager: ObservableObject {
  public static let shared = AuthTokenManager()

  /// The auth token for the authenticated user.
  @Published public private(set) var authToken: AuthToken?

  /// An identifier for the Sign in with Apple user. This may change if the account is unlinked and re-linked.
  @Published public private(set) var authenticatedUserIdentifier: UserIdentifier?

  /// Whether the user is authenticated or not.
  public var isAuthenticated: Bool {
    authToken != nil
  }

  @available(*, deprecated, message: "Use `sharedValet` instead.")
  private let valet = Valet.iCloudValet(
    with: Identifier(nonEmpty: "UserController")!,
    accessibility: .afterFirstUnlock
  )

  private let sharedValet = Valet.sharedGroupValet(
    with: SharedGroupIdentifier(groupPrefix: "group", nonEmptyGroup: .groupIdentifier)!,
    identifier: Identifier(nonEmpty: "UserController")!,
    accessibility: .afterFirstUnlock
  )

  private init() {
    // Migrate from iCloud Valet to Shared Group Valet
    for key in [String.authenticatedUserIdentifierKey, String.authTokenKey] {
      if let value = try? valet.string(forKey: key) {
        try? sharedValet.setString(value, forKey: key)
        try? valet.removeObject(forKey: key)
      }
    }

    loadFromStorage()
  }

  /// Sets the authentication credentials.
  public func setAuthentication(token: AuthToken, userIdentifier: UserIdentifier) {
    self.authToken = token
    self.authenticatedUserIdentifier = userIdentifier
    storeToStorage()
  }

  /// Replaces the stored Sign in with Apple identifier, leaving the auth token alone.
  ///
  /// Used after the developer team migration: the device may hold the identifier the old team
  /// issued, which Apple no longer resolves, while the session itself is perfectly valid.
  public func updateUserIdentifier(_ userIdentifier: UserIdentifier) {
    guard authenticatedUserIdentifier != userIdentifier else { return }

    self.authenticatedUserIdentifier = userIdentifier
    storeToStorage()
  }

  /// Clears the authentication credentials.
  public func clearAuthentication() {
    self.authToken = nil
    self.authenticatedUserIdentifier = nil
    removeFromStorage()
  }
}

// MARK: - Private Storage Methods

private extension AuthTokenManager {

  func loadFromStorage() {
    #if targetEnvironment(simulator)
    print("[AuthTokenManager] Using UserDefaults fallback for simulator authentication")
    // Simulator-specific code path - use UserDefaults only
    if let rawUserIdentifier = UserDefaults.group.string(forKey: .simulatorUserIdentifierKey) {
      self.authenticatedUserIdentifier = UserIdentifier(rawUserIdentifier)
    }

    if let rawAuthToken = UserDefaults.group.string(forKey: .simulatorAuthTokenKey) {
      self.authToken = AuthToken(rawAuthToken)
    }
    #else
    // Real device code path
    do {
      let rawUserIdentifier = try sharedValet.string(forKey: .authenticatedUserIdentifierKey)
      self.authenticatedUserIdentifier = UserIdentifier(rawUserIdentifier)
    } catch {
      print(error)
    }

    do {
      let rawAuthToken = try sharedValet.string(forKey: .authTokenKey)
      self.authToken = AuthToken(rawAuthToken)
    } catch {
      print(error)
    }
    #endif
  }

  func storeToStorage() {
    storeAuthenticatedUserIdentifier()
    storeAuthToken()
  }

  func removeFromStorage() {
    storeAuthenticatedUserIdentifier()
    storeAuthToken()
  }

  func storeAuthenticatedUserIdentifier() {
    #if targetEnvironment(simulator)
    // Simulator code path - UserDefaults only
    if let authenticatedUserIdentifier {
      UserDefaults.group.set(authenticatedUserIdentifier.value, forKey: .simulatorUserIdentifierKey)
    } else {
      UserDefaults.group.removeObject(forKey: .simulatorUserIdentifierKey)
    }
    #else
    // Real device code path
    do {
      if let authenticatedUserIdentifier {
        try sharedValet.setString(authenticatedUserIdentifier.value, forKey: .authenticatedUserIdentifierKey)
      } else {
        try sharedValet.removeObject(forKey: .authenticatedUserIdentifierKey)
      }
    } catch {
      print(error)
    }
    #endif
  }

  func storeAuthToken() {
    #if targetEnvironment(simulator)
    // Simulator code path - UserDefaults only
    if let authToken {
      UserDefaults.group.set(authToken.value, forKey: .simulatorAuthTokenKey)
    } else {
      UserDefaults.group.removeObject(forKey: .simulatorAuthTokenKey)
    }
    #else
    // Real device code path
    do {
      if let authToken {
        try sharedValet.setString(authToken.value, forKey: .authTokenKey)
      } else {
        try sharedValet.removeObject(forKey: .authTokenKey)
      }
    } catch {
      print(error)
    }
    #endif
  }
}
