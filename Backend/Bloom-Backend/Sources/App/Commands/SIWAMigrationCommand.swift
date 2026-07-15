//
//  SIWAMigrationCommand.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2026-07-13.
//

import Foundation
import Vapor
import Fluent
import BloomModel
import SignInWithApple
@preconcurrency import JWT

/// Migrates Sign in with Apple users from the legacy team to the new team after an app transfer.
///
/// All migration state is written to parallel columns on `users` (`transfer_sub`, `new_apple_id`,
/// `migrated_email`). The legacy identifier in `id` is never modified or deleted — cutover to the
/// new identifiers is a separate, later step once the mapping is verified.
///
/// Phases (run in order):
/// - `generate`: Uses the legacy team's SIWA key (`LEGACY_*` env vars) to fetch a `transfer_sub`
///   for each user. Apple only allows this for 60 days after the transfer completes.
/// - `exchange`: Uses the new team's SIWA key (the regular `SIWA_*`/`APPLE_TEAM_ID` env vars,
///   which must already point at the new team) to exchange each `transfer_sub` for the user's
///   new team-scoped identifier.
/// - `status`: Prints migration progress counts without contacting Apple.
struct SIWAMigrationCommand: AsyncCommand {

  struct Signature: CommandSignature {
    @Argument(name: "phase", help: "One of: generate, exchange, status")
    var phase: String
  }

  var help: String {
    "Migrates Sign in with Apple users to the new Apple developer team"
  }

  func run(using context: CommandContext, signature: Signature) async throws {
    let app = context.application

    switch signature.phase {
    case "generate":
      try await generateTransferSubs(app: app, console: context.console)
    case "exchange":
      try await exchangeTransferSubs(app: app, console: context.console)
    case "status":
      try await printStatus(app: app, console: context.console)
    default:
      context.console.error("Unknown phase '\(signature.phase)'. Use one of: generate, exchange, status")
    }
  }
}

// MARK: - Phases

private extension SIWAMigrationCommand {

  func generateTransferSubs(app: Application, console: any Console) async throws {
    guard !app.legacyAppleTeamID.isEmpty, !app.legacySiwAJWKId.isEmpty, !app.legacySiwAPrivateKey.isEmpty else {
      console.error("LEGACY_APPLE_TEAM_ID, LEGACY_SIWA_JWK_ID, and LEGACY_SIWA_PRIVATE_KEY must be set")
      return
    }
    guard !app.appleTeamID.isEmpty, app.appleTeamID != app.legacyAppleTeamID else {
      console.error("APPLE_TEAM_ID must be set to the new team ID before generating transfer identifiers")
      return
    }

    let clientSecret = try makeClientSecret(
      teamID: app.legacyAppleTeamID,
      clientID: app.bloomAppBundleID,
      privateKey: try app.createLegacySiwAPrivateKey()
    )
    let accessToken = try await fetchMigrationAccessToken(app: app, clientSecret: clientSecret)

    let users = try await User.query(on: app.db)
      .filter(\.$transferSub == nil)
      .all()

    console.print("Generating transfer identifiers for \(users.count) user(s)")

    var succeeded = 0
    var failed = 0

    for user in users {
      guard let userID = user.id?.value else { continue }

      do {
        let response = try await postUserMigrationInfo(
          app: app,
          accessToken: accessToken,
          body: [
            "sub": userID,
            "target": app.appleTeamID,
            "client_id": app.bloomAppBundleID,
            "client_secret": clientSecret
          ]
        )
        user.transferSub = try response.content.decode(TransferSubResponse.self).transferSub
        try await user.save(on: app.db)
        succeeded += 1
      } catch {
        // Expected for accounts that never belonged to the legacy team
        // (e.g. rows created by post-transfer sign-ins with new-team identifiers).
        failed += 1
        console.error("Failed to generate transfer_sub for user \(userID): \(error)")
      }

      try await Task.sleep(nanoseconds: 100_000_000)
    }

    console.print("Generate complete. Succeeded: \(succeeded), failed: \(failed)")
  }

  func exchangeTransferSubs(app: Application, console: any Console) async throws {
    guard !app.appleTeamID.isEmpty, app.appleTeamID != app.legacyAppleTeamID else {
      console.error("APPLE_TEAM_ID must be set to the new team ID before exchanging transfer identifiers")
      return
    }

    let clientSecret = try makeClientSecret(
      teamID: app.appleTeamID,
      clientID: app.bloomAppBundleID,
      privateKey: try app.createBloomSiwAPrivateKey()
    )
    let accessToken = try await fetchMigrationAccessToken(app: app, clientSecret: clientSecret)

    let users = try await User.query(on: app.db)
      .filter(\.$transferSub != nil)
      .filter(\.$newAppleID == nil)
      .all()

    console.print("Exchanging transfer identifiers for \(users.count) user(s)")

    var succeeded = 0
    var failed = 0
    var collisions = 0

    for user in users {
      guard let userID = user.id?.value, let transferSub = user.transferSub else { continue }

      do {
        let response = try await postUserMigrationInfo(
          app: app,
          accessToken: accessToken,
          body: [
            "transfer_sub": transferSub,
            "client_id": app.bloomAppBundleID,
            "client_secret": clientSecret
          ]
        )
        let result = try response.content.decode(ExchangeResponse.self)

        // A row keyed by the new identifier means this user signed in fresh after the
        // transfer and got a duplicate account. Don't link the mapping automatically —
        // flag it for a manual merge decision. Nothing is deleted.
        if let shadow = try await User.find(UserIdentifier(result.sub), on: app.db),
           shadow.id?.value != userID {
          collisions += 1
          console.error("Collision: user \(userID) maps to \(result.sub), which already exists as a separate account. Manual merge needed.")
          continue
        }

        user.newAppleID = result.sub
        user.migratedEmail = result.email
        try await user.save(on: app.db)
        succeeded += 1
      } catch {
        failed += 1
        console.error("Failed to exchange transfer_sub for user \(userID): \(error)")
      }

      try await Task.sleep(nanoseconds: 100_000_000)
    }

    console.print("Exchange complete. Succeeded: \(succeeded), failed: \(failed), collisions: \(collisions)")
  }

  func printStatus(app: Application, console: any Console) async throws {
    let total = try await User.query(on: app.db).count()
    let withTransferSub = try await User.query(on: app.db).filter(\.$transferSub != nil).count()
    let withNewAppleID = try await User.query(on: app.db).filter(\.$newAppleID != nil).count()

    console.print("Total users: \(total)")
    console.print("With transfer_sub (generate done): \(withTransferSub)")
    console.print("With new_apple_id (exchange done): \(withNewAppleID)")
    console.print("Awaiting generate: \(total - withTransferSub)")
    console.print("Awaiting exchange: \(withTransferSub - withNewAppleID)")
  }
}

// MARK: - Apple API

private extension SIWAMigrationCommand {

  func makeClientSecret(teamID: String, clientID: String, privateKey: ApplePrivateKey) throws -> String {
    let payload = MigrationClientSecret(teamID: teamID, clientID: clientID)
    let signer = JWTSigner.es256(key: privateKey.key)
    return try signer.sign(payload, kid: privateKey.kid)
  }

  func fetchMigrationAccessToken(app: Application, clientSecret: String) async throws -> String {
    let response = try await app.client.post("https://appleid.apple.com/auth/token") { request in
      try request.content.encode(
        [
          "grant_type": "client_credentials",
          "scope": "user.migration",
          "client_id": app.bloomAppBundleID,
          "client_secret": clientSecret
        ],
        as: .urlEncodedForm
      )
    }

    guard response.status == .ok else {
      throw SIWAMigrationError.appleError(status: response.status, body: response.bodyString)
    }

    return try response.content.decode(AccessTokenResponse.self).accessToken
  }

  func postUserMigrationInfo(
    app: Application,
    accessToken: String,
    body: [String: String],
    attempt: Int = 1
  ) async throws -> ClientResponse {
    let response = try await app.client.post("https://appleid.apple.com/auth/usermigrationinfo") { request in
      request.headers.bearerAuthorization = BearerAuthorization(token: accessToken)
      try request.content.encode(body, as: .urlEncodedForm)
    }

    if response.status == .tooManyRequests, attempt < 3 {
      app.logger.warning("Rate limited by Apple; sleeping 30s before retry (attempt \(attempt))")
      try await Task.sleep(nanoseconds: 30_000_000_000)
      return try await postUserMigrationInfo(app: app, accessToken: accessToken, body: body, attempt: attempt + 1)
    }

    guard response.status == .ok else {
      throw SIWAMigrationError.appleError(status: response.status, body: response.bodyString)
    }

    return response
  }
}

// MARK: - Models

private struct MigrationClientSecret: JWTPayload {
  let iss: String
  let iat: Int
  let exp: Int
  let aud: String
  let sub: String

  init(teamID: String, clientID: String) {
    iss = teamID
    iat = Int(Date().timeIntervalSince1970)
    exp = iat + 3600
    aud = "https://appleid.apple.com"
    sub = clientID
  }

  func verify(using signer: JWTSigner) throws { }
}

private struct AccessTokenResponse: Content {
  let accessToken: String

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
  }
}

private struct TransferSubResponse: Content {
  let transferSub: String

  enum CodingKeys: String, CodingKey {
    case transferSub = "transfer_sub"
  }
}

private struct ExchangeResponse: Content {
  let sub: String
  let email: String?

  enum CodingKeys: String, CodingKey {
    case sub
    case email
  }
}

private enum SIWAMigrationError: Error, CustomStringConvertible {
  case appleError(status: HTTPResponseStatus, body: String)

  var description: String {
    switch self {
    case .appleError(let status, let body):
      return "Apple returned \(status.code): \(body)"
    }
  }
}

private extension ClientResponse {

  var bodyString: String {
    guard let body else { return "<empty>" }
    return String(buffer: body)
  }
}
