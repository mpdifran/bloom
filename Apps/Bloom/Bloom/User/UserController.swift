//
//  UserController.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-19.
//

import SwiftUI
import BloomModel
import TelemetryDeck
import RevenueCat
import AuthenticationServices
import CoreHealth
import CoreNetwork

@MainActor
final class UserController: ObservableObject {
  static let shared = UserController()

  private init() {
    if let lastIdentifyDate = UserDefaults.group.object(forKey: "UserController.lastIdentifyDate") as? Date {
      self.lastIdentifyDate = lastIdentifyDate
    }

    if let data = try? Data(contentsOf: profilePhotoURL) {
      profilePhoto = UIImage(data: data)
    }
  }

  @AppStorage("UserController.email", store: .group) var email: String?
  @AppStorage("UserController.givenName", store: .group) var givenName: String?
  @AppStorage("UserController.familyName", store: .group) var familyName: String?
  @Published var profilePhoto: UIImage? {
    didSet {
      if let data = profilePhoto?.resized(toWidth: 300)?.pngData() {
        try? data.write(to: profilePhotoURL)
      } else {
        try? FileManager.default.removeItem(at: profilePhotoURL)
      }
    }
  }

  private let profilePhotoURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: .groupSuiteName)!.appendingPathComponent("profile_photo.png")

  private var lastIdentifyDate: Date? {
    didSet { UserDefaults.group.set(lastIdentifyDate, forKey: "UserController.lastIdentifyDate") }
  }

  var isAuthenticated: Bool {
    AuthTokenManager.shared.isAuthenticated
  }
}

extension UserController {

  var fullUserIdentifier: String {
    let name = [givenName, familyName].compactMap({ $0 }).joined(separator: " ")
    if name.isNotEmpty {
      return name
    }
    if let email {
      return email
    }
    return "Anonymous"
  }

  func verifyAuthentication() async throws {
    guard let userIdentifier = AuthTokenManager.shared.authenticatedUserIdentifier else { return }

    #if targetEnvironment(simulator)
    // Skip verification on simulator as it will always fail
    // Simulator doesn't maintain Apple ID credential state properly
    return
    #else
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
    #endif
  }

  func identify() async {
    do {
      if email != nil || givenName != nil || familyName != nil {
        if let lastIdentifyDate, lastIdentifyDate.timeIntervalSinceNow > -7 * 24 * 60 * 60 {
          return // We've already checked recently.
        }
      }

      let requestBody = AuthIdentifyRequest(
        appUserID: UserID.value,
        appVersion: Bundle.main.appVersion ?? "Unknown"
      )
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

    // Store auth token and user identifier in AuthTokenManager
    AuthTokenManager.shared.setAuthentication(
      token: authResponse.authToken,
      userIdentifier: userIdentifier
    )

    // Set the user's name automatically if it's not already provided.
    if let name = authResponse.identity.givenName {
      await MainActor.run {
        guard HealthManager.shared.name.isEmpty else { return }

        HealthManager.shared.name = name
      }
    }

    // Notify token manager of authentication state change
    // This will handle remote notification registration if needed
    await PushNotificationTokenManager.shared.handleAuthenticationStateChange(isAuthenticated: true)
  }

  func logout() async throws {
    try await NetworkRequester.shared.signOut()

    // Clear authentication
    AuthTokenManager.shared.clearAuthentication()

    email = nil
    givenName = nil
    familyName = nil
    lastIdentifyDate = nil

    registerDetailsWithRevenueCat()

    // Notify token manager of logout
    await PushNotificationTokenManager.shared.handleAuthenticationStateChange(isAuthenticated: false)
  }

  func deleteAccount() async throws {
    try await NetworkRequester.shared.deleteAccount()

    // Clear authentication
    AuthTokenManager.shared.clearAuthentication()

    email = nil
    givenName = nil
    familyName = nil
    lastIdentifyDate = nil

    registerDetailsWithRevenueCat()

    // Notify token manager of account deletion
    await PushNotificationTokenManager.shared.handleAuthenticationStateChange(isAuthenticated: false)
  }
  
  func updatePushNotificationToken(_ token: String) async throws {
    try await NetworkRequester.shared.register(deviceToken: token)
  }

  func updateConsent(healthData: Bool, externalProcessing: Bool) async throws -> ConsentResponse {
    let request = UpdateConsentRequest(
      healthDataConsent: healthData,
      externalProcessingConsent: externalProcessing
    )
    return try await NetworkRequester.shared.updateConsent(request: request)
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
}
