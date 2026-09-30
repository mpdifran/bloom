//
//  CrashAuthMiddleware.swift
//  Bloom-Backend
//

import Vapor

/// Gates crash submission from the apps.
///
/// Not the user's auth token: crashes happen before sign-in, in extensions and on the watch, none
/// of which reliably hold one - and tying a crash to an account would change the App Store privacy
/// answer. The key is compiled into a shipped binary, so anybody willing to run `strings` can read
/// it. That is understood: this keeps crawlers and idle scanners out of the table, and the rate
/// limits in `CrashController` are what actually protect the database.
///
/// - A custom header rather than `Authorization: Bearer`, so the key can never be mistaken for -
///   or tried as - a user token.
/// - A wrong or missing key gets **404**, not 401. A 401 tells a scanner it found something.
struct CrashIngestKeyMiddleware: AsyncMiddleware {
  static let headerName = "X-Crash-Ingest-Key"

  func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
    let keys = request.application.crashIngestKeys

    guard !keys.isEmpty else {
      request.logger.warning("Crash ingest attempted with CRASH_INGEST_KEY unset")
      throw Abort(.notFound)
    }

    guard
      let presented = request.headers.first(name: Self.headerName),
      keys.contains(where: { ConstantTime.equals($0, presented) })
    else {
      throw Abort(.notFound)
    }

    return try await next.respond(to: request)
  }
}

/// Gates the crash admin endpoints behind `CRASH_ADMIN_SECRET`.
///
/// A shared secret rather than Gardener's admin sign-in, because the callers are scripts: the
/// Xcode Cloud build registering dSYMs, the symbolicator and the daily triage job.
struct CrashAdminSecretMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
    guard
      let secret = request.application.crashAdminSecret,
      let bearer = request.headers.bearerAuthorization,
      ConstantTime.equals(bearer.token, secret)
    else {
      throw Abort(.unauthorized)
    }

    return try await next.respond(to: request)
  }
}

/// Comparison that doesn't short-circuit, so a secret can't be recovered a byte at a time from
/// response timing.
enum ConstantTime {
  static func equals(_ lhs: String, _ rhs: String) -> Bool {
    let a = Array(lhs.utf8)
    let b = Array(rhs.utf8)
    var diff: UInt8 = a.count == b.count ? 0 : 1
    for i in 0..<min(a.count, b.count) {
      diff |= a[i] ^ b[i]
    }
    return diff == 0
  }
}
