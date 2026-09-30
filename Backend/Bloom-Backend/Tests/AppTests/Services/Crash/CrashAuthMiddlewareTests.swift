//
//  CrashAuthMiddlewareTests.swift
//  Bloom-Backend
//

@testable import App
import Foundation
import Testing
import XCTVapor

/// The only thing standing between the crash table and anyone who runs `strings` on the app is the
/// ingest key and the rate limits behind it. The key itself is not a secret; refusing everything
/// that does not present it still has to be exact.
@Suite("CrashAuthMiddleware", .serialized)
struct CrashAuthMiddlewareTests {

  private func withEnvironment(_ name: String, _ value: String?, _ body: () async throws -> Void) async rethrows {
    let previous = getenv(name).map { String(cString: $0) }
    if let value {
      setenv(name, value, 1)
    } else {
      unsetenv(name)
    }
    defer {
      if let previous {
        setenv(name, previous, 1)
      } else {
        unsetenv(name)
      }
    }
    try await body()
  }

  private func withApp(
    _ middleware: some AsyncMiddleware,
    _ body: (Application) async throws -> Void
  ) async throws {
    let app = try await Application.make(.testing)
    app.grouped(middleware).get("test") { _ in "ok" }
    do {
      try await body(app)
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }

  // MARK: Ingest key

  @Test("Correct ingest key passes through")
  func correctKey() async throws {
    try await withEnvironment("CRASH_INGEST_KEY", "secret-key") {
      try await withApp(CrashIngestKeyMiddleware()) { app in
        try await app.test(.GET, "test", headers: [CrashIngestKeyMiddleware.headerName: "secret-key"]) { res async in
          #expect(res.status == .ok)
        }
      }
    }
  }

  @Test("A second, rotated key is also accepted")
  func rotatedKey() async throws {
    try await withEnvironment("CRASH_INGEST_KEY", "current-key, previous-key") {
      try await withApp(CrashIngestKeyMiddleware()) { app in
        try await app.test(.GET, "test", headers: [CrashIngestKeyMiddleware.headerName: "previous-key"]) { res async in
          #expect(res.status == .ok, "A build in the wild keeps working while a key is rotated")
        }
      }
    }
  }

  @Test("Wrong ingest key returns 404, not 401")
  func wrongKey() async throws {
    try await withEnvironment("CRASH_INGEST_KEY", "secret-key") {
      try await withApp(CrashIngestKeyMiddleware()) { app in
        try await app.test(.GET, "test", headers: [CrashIngestKeyMiddleware.headerName: "wrong-key"]) { res async in
          #expect(res.status == .notFound, "A 401 tells a scanner it found something")
        }
      }
    }
  }

  @Test("Missing ingest header returns 404")
  func missingHeader() async throws {
    try await withEnvironment("CRASH_INGEST_KEY", "secret-key") {
      try await withApp(CrashIngestKeyMiddleware()) { app in
        try await app.test(.GET, "test") { res async in
          #expect(res.status == .notFound)
        }
      }
    }
  }

  @Test("Unset ingest key refuses everything")
  func unsetIngestKey() async throws {
    try await withEnvironment("CRASH_INGEST_KEY", nil) {
      try await withApp(CrashIngestKeyMiddleware()) { app in
        try await app.test(.GET, "test", headers: [CrashIngestKeyMiddleware.headerName: "anything"]) { res async in
          #expect(res.status == .notFound, "An unconfigured deploy must not accept an empty key")
        }
      }
    }
  }

  // MARK: Admin secret

  @Test("Admin secret is required")
  func adminSecret() async throws {
    try await withEnvironment("CRASH_ADMIN_SECRET", "admin-secret") {
      try await withApp(CrashAdminSecretMiddleware()) { app in
        try await app.test(.GET, "test", headers: ["Authorization": "Bearer admin-secret"]) { res async in
          #expect(res.status == .ok)
        }
        try await app.test(.GET, "test", headers: ["Authorization": "Bearer nope"]) { res async in
          #expect(res.status == .unauthorized)
        }
      }
    }
  }

  @Test("Unset admin secret refuses everything")
  func unsetAdminSecret() async throws {
    try await withEnvironment("CRASH_ADMIN_SECRET", nil) {
      try await withApp(CrashAdminSecretMiddleware()) { app in
        try await app.test(.GET, "test", headers: ["Authorization": "Bearer "]) { res async in
          #expect(res.status == .unauthorized)
        }
      }
    }
  }

  // MARK: App allow-list

  @Test("Known apps resolve")
  func knownApps() throws {
    #expect(try CrashApp(pathComponent: "bloom") == .bloom)
    #expect(try CrashApp(pathComponent: "Bloom") == .bloom)
    #expect(try CrashApp(pathComponent: "bloom-watch") == .bloomWatch)
  }

  @Test("Unknown app is refused")
  func unknownApp() {
    #expect(throws: (any Error).self) {
      try CrashApp(pathComponent: "not-an-app")
    }
  }
}
