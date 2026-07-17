//
//  Application+Keys.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-09.
//

import Vapor
import SignInWithApple
import JWT
import OpenAIKit

extension Application {

  func printEnvironmentInfo() {
    logger.notice("Environment: \(environment.name)")
    if environment == .production {
      logger.logLevel = .info
    } else {
      logger.logLevel = .debug
    }

    LogHelper.shared.set(logLevel: .warning)

    if let _ = postgresURL {
      logger.notice("Postgres URL set")
    } else {
      logger.notice("Using local Postgres")
    }
  }
}

// MARK: - App-Site Association

extension Application {

  var appleAppSiteAssociationFilepath: String {
      switch environment {
      case .production: return "Resources/association-prod.json"
      case .development: return "Resources/association-dev.json"
      default: fatalError("No domain for unknown environment.")
      }
  }
}

// MARK: - APNs

extension Application {

  var bloomAPNsJWKID: String {
    Environment.get("APNS_JWK_ID") ?? ""
  }

  var bloomAPNsPrivateKey: String {
    Environment.get("APNS_PRIVATE_KEY") ?? ""
  }
}

// MARK: - Sign in with Apple

extension Application {

  var appleTeamID: String {
    Environment.get("APPLE_TEAM_ID") ?? ""
  }

  var bloomAppBundleID: String {
    switch environment {
    case .production:
      "com.lotus-labs.bloom"
    default:
      "com.lotus-labs.bloom.dev"
    }
  }

  var bloomSiwAJWKId: String {
    Environment.get("SIWA_JWK_ID") ?? ""
  }

  var bloomSiwAPrivateKey: String {
    Environment.get("SIWA_PRIVATE_KEY") ?? ""
  }

  func createBloomSiwAPrivateKey() throws -> ApplePrivateKey {
    try ApplePrivateKey(
      kid: JWKIdentifier(string: bloomSiwAJWKId),
      privateKey: bloomSiwAPrivateKey
    )
  }

  /// The team ID the app belonged to before the transfer to the personal team.
  /// Only needed while running the SIWA user migration (valid for 60 days post-transfer).
  var legacyAppleTeamID: String {
    Environment.get("LEGACY_APPLE_TEAM_ID") ?? ""
  }

  var legacySiwAJWKId: String {
    Environment.get("LEGACY_SIWA_JWK_ID") ?? ""
  }

  var legacySiwAPrivateKey: String {
    Environment.get("LEGACY_SIWA_PRIVATE_KEY") ?? ""
  }

  func createLegacySiwAPrivateKey() throws -> ApplePrivateKey {
    try ApplePrivateKey(
      kid: JWKIdentifier(string: legacySiwAJWKId),
      privateKey: legacySiwAPrivateKey
    )
  }

  var gardenerAppBundleID: String {
    "com.lotus-labs.gardener"
  }

  /// Gardener was not transferred with the main app, so it can remain on a different
  /// team than `APPLE_TEAM_ID`. Falls back to the main team ID when unset.
  var gardenerAppleTeamID: String {
    Environment.get("GARDENER_APPLE_TEAM_ID") ?? appleTeamID
  }

  var gardenerSiwAJWKId: String {
    Environment.get("GARDENER_SIWA_JWK_ID") ?? ""
  }

  var gardenerSiwAPrivateKey: String {
    Environment.get("GARDENER_SIWA_PRIVATE_KEY") ?? ""
  }

  func createGardenerSiwAPrivateKey() throws -> ApplePrivateKey {
    try ApplePrivateKey(
      kid: JWKIdentifier(string: gardenerSiwAJWKId),
      privateKey: gardenerSiwAPrivateKey
    )
  }

  func adminEmailAllowList() -> [String] {
    let emails = Environment.get("GARDENER_ADMIN_EMAIL_ALLOWLIST") ?? ""
    return emails.components(separatedBy: ",").map({
      $0
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
    })
  }
}

// MARK: - USDA

extension Application {

  var usdaAPIKey: String? {
    Environment.get("USDA_API_KEY")
  }

  var usdaDomain: String {
    "https://api.nal.usda.gov/fdc"
  }
}

// MARK: - Postgres

extension Application {

  var postgresURL: URL? {
    guard let urlString = Environment.get("DATABASE_URL") else {
      return nil
    }
    return URL(string: urlString)
  }

  var localhostUsername: String? {
    Environment.get("POSTGRES_LOCALHOST_USERNAME")
  }

  var localhostPassword: String? {
    Environment.get("POSTGRES_LOCALHOST_PASSWORD")
  }
}

// MARK: - Redis

extension Application {

  var redisURL: URL? {
    guard let urlString = Environment.get("REDIS_URL") else { return nil }

    return URL(string: urlString)
  }

  var redisHostname: String {
    Environment.get("REDIS_HOST") ?? "127.0.0.1"
  }

  var redisPort: Int {
    Environment.get("REDIS_PORT").flatMap(Int.init) ?? 6379
  }

  var redisPassword: String? {
    Environment.get("REDIS_PASSWORD")
  }
}

// MARK: - MailerLite

extension Application {

  var mailerLiteAPIKey: String? {
    Environment.get("MAILERLITE_API_KEY")
  }

  var mailerLiteCancelledGroupID: String? {
    Environment.get("MAILERLITE_CANCELLED_GROUP_ID")
  }
}

// MARK: - MailerLite Groups

extension Application {

  var mailerLiteFreeUsersGroupID: String? {
    Environment.get("MAILERLITE_FREE_USERS_GROUP_ID")
  }
}

// MARK: - RevenueCat

extension Application {

  var revenueCatWebhookSecret: String? {
    Environment.get("REVENUECAT_WEBHOOK_SECRET")
  }

  var revenueCatAPIKey: String? {
    Environment.get("REVENUECAT_API_KEY")
  }
}

// MARK: - Chat Configuration

extension Application {

  var maxChatToolCallsPerMessage: Int {
    Environment.get("MAX_CHAT_TOOL_CALLS_PER_MESSAGE").flatMap(Int.init) ?? 5
  }
}
