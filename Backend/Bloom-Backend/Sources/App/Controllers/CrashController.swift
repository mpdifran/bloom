//
//  CrashController.swift
//  Bloom-Backend
//

import Fluent
import Vapor

/// Crash submission from the apps. See `CrashIngestKeyMiddleware` for why this isn't behind user
/// auth.
struct CrashController { }

extension CrashController: RouteCollection {

  /// The newest payload shape this build understands. A client sending something newer is refused
  /// outright rather than half-read.
  static let currentSchemaVersion = 1

  /// Per install, per hour. A crash loop on one device reports the same thing every launch.
  static let installHourlyLimit = 20

  /// Across every install of one app, per hour. This is the limit that actually protects the
  /// database: the install id comes from the client, so anyone can rotate past the first one.
  static let appHourlyLimit = 2_000

  /// A second report of the same crash inside this window is dropped.
  static let dedupeWindow: TimeInterval = 15 * 60

  /// Stacks and raw reports are big, and a real one is well past Vapor's 16 KB default.
  static let maximumBodySize: ByteCount = "256kb"

  /// Enough of Apple's report to be useful, not so much that the table fills with it.
  static let rawReportLimit = 32_000

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1", "apps", ":app") {
      $0.grouped(CrashIngestKeyMiddleware())
        .on(.POST, "crashes", body: .collect(maxSize: Self.maximumBodySize), use: submit)
    }
  }
}

private extension CrashController {

  @Sendable
  func submit(_ request: Request) async throws -> Response {
    let app = try CrashApp(request: request)
    let payload = try request.content.decode(SubmitCrashRequest.self)

    guard payload.schemaVersion <= Self.currentSchemaVersion else {
      throw Abort(.badRequest, reason: "Unsupported crash schema version")
    }

    let oneHourAgo = Date(timeIntervalSinceNow: -3600)

    let appCount = try await CrashReport.query(on: request.db)
      .filter(\.$app == app.rawValue)
      .filter(\.$createdAt > oneHourAgo)
      .count()
    guard appCount < Self.appHourlyLimit else {
      throw Abort(.tooManyRequests, reason: "Crash report rate limit exceeded")
    }

    let installCount = try await CrashReport.query(on: request.db)
      .filter(\.$app == app.rawValue)
      .filter(\.$installID == payload.installID)
      .filter(\.$createdAt > oneHourAgo)
      .count()
    guard installCount < Self.installHourlyLimit else {
      throw Abort(.tooManyRequests, reason: "Crash report rate limit exceeded")
    }

    // The same crash reaches us from the signal handler and from MetricKit. Answer 200 for the
    // second one: a 4xx would leave a well-behaved client retrying it forever.
    if let dedupeKey = payload.dedupeKey {
      let recent = try await CrashReport.query(on: request.db)
        .filter(\.$app == app.rawValue)
        .filter(\.$installID == payload.installID)
        .filter(\.$dedupeKey == dedupeKey)
        .filter(\.$createdAt > Date(timeIntervalSinceNow: -Self.dedupeWindow))
        .first()

      if let recent {
        return try await SubmitCrashResponse(id: recent.id, deduped: true)
          .encodeResponse(status: .ok, for: request)
      }
    }

    let report = CrashReport(
      app: app.rawValue,
      installID: payload.installID,
      source: payload.source,
      dedupeKey: payload.dedupeKey,
      appVersion: payload.appVersion,
      buildNumber: payload.buildNumber,
      osVersion: payload.osVersion,
      deviceModel: payload.deviceModel,
      processName: payload.processName,
      exceptionType: payload.exceptionType,
      exceptionCode: payload.exceptionCode,
      signalName: payload.signalName,
      terminationReason: payload.terminationReason,
      crashThread: payload.crashThread,
      stackTrace: payload.stackTrace,
      rawReport: payload.rawReport.map { String($0.prefix(Self.rawReportLimit)) },
      binaryImages: payload.binaryImages,
      frames: payload.frames,
      schemaVersion: payload.schemaVersion,
      crashedAt: payload.crashedAt
    )

    try await report.save(on: request.db)
    try await CrashGrouping.group(report, on: request.db)

    request.logger.info("\(app.rawValue) crash: \(payload.exceptionType) in \(payload.appVersion) (\(payload.buildNumber)) via \(payload.source)")

    return try await SubmitCrashResponse(id: report.id, deduped: false)
      .encodeResponse(status: .created, for: request)
  }
}
