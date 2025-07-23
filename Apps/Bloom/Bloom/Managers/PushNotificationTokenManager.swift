import Foundation
import UIKit
import OSLog

@MainActor
final class PushNotificationTokenManager: ObservableObject {
  static let shared = PushNotificationTokenManager()

  private let logger = Logger(subsystem: "com.diffranfoundation.bloom", category: "PushNotificationTokenManager")

  @Published private(set) var currentToken: String?
  @Published private(set) var isRegistering = false
  @Published private(set) var lastRegistrationError: Error?

  private let tokenKey = "com.bloom.apns.deviceToken"
  private let lastRegistrationKey = "com.bloom.apns.lastRegistration"
  private let tokenRefreshInterval: TimeInterval = 24 * 60 * 60 // 24 hours

  private var registrationRetryCount = 0
  private let maxRetryAttempts = 3
  private let retryDelay: TimeInterval = 5.0

  private init() {
    loadStoredToken()
  }

  // MARK: - Token Management

  func handleNewToken(_ tokenData: Data) async {
    let tokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()

    logger.info("Received new APNs token")

    let tokenChanged = await checkIfTokenChanged(tokenString)

    if tokenChanged {
      logger.info("Token changed, updating backend")
      await registerTokenWithBackend(tokenString)
    } else if shouldRefreshToken() {
      logger.info("Token refresh interval exceeded, re-registering")
      await registerTokenWithBackend(tokenString)
    } else {
      logger.info("Token unchanged and within refresh interval, skipping registration")
      currentToken = tokenString
    }
  }

  func refreshTokenIfNeeded() async {
    guard shouldRefreshToken() else {
      logger.info("Token refresh not needed")
      return
    }

    logger.info("Initiating token refresh")
    requestNotificationPermissions()
  }

  func clearToken() {
    UserDefaults.standard.removeObject(forKey: tokenKey)
    UserDefaults.standard.removeObject(forKey: lastRegistrationKey)
    currentToken = nil
    logger.info("Cleared stored token")
  }

  // MARK: - Private Methods

  private func loadStoredToken() {
    currentToken = UserDefaults.standard.string(forKey: tokenKey)
  }

  private func checkIfTokenChanged(_ newToken: String) async -> Bool {
    let storedToken = UserDefaults.standard.string(forKey: tokenKey)
    return storedToken != newToken
  }

  private func shouldRefreshToken() -> Bool {
    guard let lastRegistration = UserDefaults.standard.object(forKey: lastRegistrationKey) as? Date else {
      return true
    }

    return Date().timeIntervalSince(lastRegistration) > tokenRefreshInterval
  }

  private func storeToken(_ token: String) {
    UserDefaults.standard.set(token, forKey: tokenKey)
    UserDefaults.standard.set(Date(), forKey: lastRegistrationKey)
    currentToken = token
  }

  private func registerTokenWithBackend(_ token: String) async {
    isRegistering = true
    lastRegistrationError = nil
    registrationRetryCount = 0

    await performRegistrationWithRetry(token)
  }

  private func performRegistrationWithRetry(_ token: String) async {
    do {
      try await UserController.shared.updatePushNotificationToken(token)
      storeToken(token)
      registrationRetryCount = 0
      isRegistering = false
      logger.info("Successfully registered token with backend")
    } catch {
      lastRegistrationError = error
      logger.error("Failed to register token: \(error.localizedDescription)")

      if registrationRetryCount < self.maxRetryAttempts {
        registrationRetryCount += 1
        logger.info("Retrying token registration (attempt \(self.registrationRetryCount)/\(self.maxRetryAttempts))")

        try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
        await performRegistrationWithRetry(token)
      } else {
        isRegistering = false
        logger.error("Max retry attempts reached for token registration")
      }
    }
  }

  private func requestNotificationPermissions() {
    UIApplication.shared.registerForRemoteNotifications()
  }

  // MARK: - Notification Handling

  func handleFailedRegistration(_ error: Error) {
    lastRegistrationError = error
    logger.error("APNs registration failed: \(error.localizedDescription)")
  }

  func handleAuthenticationStateChange(isAuthenticated: Bool) async {
    if isAuthenticated {
      await refreshTokenIfNeeded()
    } else {
      clearToken()
    }
  }
}
