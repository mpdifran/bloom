//
//  AdminCrashController.swift
//  Bloom-Backend
//

import Fluent
import SotoS3
import Vapor

/// Reading and maintaining crashes, plus the dSYM index the symbolicator reads.
///
/// Behind `CRASH_ADMIN_SECRET`; see `CrashAdminSecretMiddleware`.
struct AdminCrashController { }

extension AdminCrashController: RouteCollection {

  static let defaultLimit = 50
  static let maximumLimit = 200

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1", "admin", "apps", ":app") {
      let app = $0.grouped(CrashAdminSecretMiddleware())

      app.group("crashes") {
        $0.get("reports", use: reports)
        $0.get("unsymbolicated", use: unsymbolicated)
        $0.get("summary", use: summary)
        $0.group(":crashID") {
          $0.get(use: report)
          $0.put("symbolicate", use: symbolicate)
        }
        $0.group("groups", ":groupID") {
          $0.patch(use: updateGroup)
        }
      }

      app.group("dsyms") {
        $0.post(use: registerDSYMs)
        $0.get(use: listDSYMs)
        $0.post("upload-url", use: dsymUploadURL)
      }
    }
  }
}

// MARK: - Reports

private extension AdminCrashController {

  @Sendable
  func reports(_ request: Request) async throws -> [CrashReportResponse] {
    let app = try CrashApp(request: request)

    let limit = min(max(request.query[Int.self, at: "limit"] ?? Self.defaultLimit, 1), Self.maximumLimit)
    var query = CrashReport.query(on: request.db)
      .filter(\.$app == app.rawValue)

    if let buildNumber = request.query[String.self, at: "buildNumber"] {
      query = query.filter(\.$buildNumber == buildNumber)
    }
    if let appVersion = request.query[String.self, at: "appVersion"] {
      query = query.filter(\.$appVersion == appVersion)
    }
    if let source = request.query[String.self, at: "source"] {
      query = query.filter(\.$source == source)
    }
    if let groupID = request.query[UUID.self, at: "crashGroupID"] {
      query = query.filter(\.$crashGroupID == groupID)
    }
    // Decoded as a string first: Vapor's Bool query decoding rejects "true"/"false" here.
    if let symbolicated = request.query[String.self, at: "symbolicated"] {
      query = query.filter(\.$isSymbolicated == (symbolicated == "true"))
    }

    return try await query
      .sort(\.$createdAt, .descending)
      .limit(limit)
      .all()
      .map(CrashReportResponse.init(from:))
  }

  @Sendable
  func report(_ request: Request) async throws -> CrashReportResponse {
    let app = try CrashApp(request: request)
    return try await CrashReportResponse(from: findReport(request, app: app))
  }

  /// The symbolication worklist, each report carrying the dSYMs its own images need.
  ///
  /// The join happens here so the symbolicator makes one call and never has to work out which dSYM
  /// belongs to which frame.
  @Sendable
  func unsymbolicated(_ request: Request) async throws -> [UnsymbolicatedCrashResponse] {
    let app = try CrashApp(request: request)

    let limit = min(max(request.query[Int.self, at: "limit"] ?? 100, 1), Self.maximumLimit)
    let reports = try await CrashReport.query(on: request.db)
      .filter(\.$app == app.rawValue)
      .filter(\.$isSymbolicated == false)
      .sort(\.$createdAt, .descending)
      .limit(limit)
      .all()

    let uuids = Set(reports.flatMap { ($0.binaryImages ?? []).map(\.uuid) })

    let dsyms: [DSYMRecord]
    if uuids.isEmpty {
      dsyms = []
    } else {
      // Not filtered by app: the watch app's binaries are built and registered alongside the
      // iOS app's, and a UUID identifies one binary whichever app it belongs to.
      dsyms = try await DSYMRecord.query(on: request.db)
        .filter(\.$uuid ~~ Array(uuids))
        .all()
    }
    let dsymsByUUID = Dictionary(dsyms.map { ($0.uuid, $0) }, uniquingKeysWith: { first, _ in first })

    // Signed once per zip rather than once per binary: a build's dSYMs share one.
    var signed = [String: String]()
    for dsym in dsyms where signed[dsym.downloadURL] == nil {
      signed[dsym.downloadURL] = try await DSYMStorage.downloadURL(for: dsym.downloadURL, on: request)
    }

    return try reports.map { report in
      let needed = (report.binaryImages ?? []).compactMap { dsymsByUUID[$0.uuid] }
      return UnsymbolicatedCrashResponse(
        report: try CrashReportResponse(from: report),
        dsyms: needed.map { DSYMResponse(from: $0, downloadURL: signed[$0.downloadURL] ?? $0.downloadURL) }
      )
    }
  }

  /// Stores a symbolicated trace and regroups the report now that its top frame has a name.
  @Sendable
  func symbolicate(_ request: Request) async throws -> HTTPStatus {
    let app = try CrashApp(request: request)
    let report = try await findReport(request, app: app)

    let payload = try request.content.decode(SymbolicateCrashRequest.self)
    report.symbolicatedTrace = payload.symbolicatedTrace
    report.isSymbolicated = true
    try await report.save(on: request.db)

    try await CrashGrouping.group(report, on: request.db)

    return .ok
  }

  func findReport(_ request: Request, app: CrashApp) async throws -> CrashReport {
    guard
      let id = request.parameters.get("crashID", as: UUID.self),
      let report = try await CrashReport.find(id, on: request.db),
      report.app == app.rawValue
    else {
      throw Abort(.notFound)
    }
    return report
  }
}

// MARK: - Groups

private extension AdminCrashController {

  @Sendable
  func summary(_ request: Request) async throws -> CrashSummaryResponse {
    let app = try CrashApp(request: request)

    let groups = try await CrashGroup.query(on: request.db)
      .filter(\.$app == app.rawValue)
      .sort(\.$lastSeenAt, .descending)
      .all()

    var responses = [CrashGroupResponse]()
    for group in groups {
      let count = try await CrashReport.query(on: request.db)
        .filter(\.$crashGroupID == group.requireID())
        .count()
      responses.append(try CrashGroupResponse(from: group, occurrenceCount: count))
    }
    responses.sort { $0.occurrenceCount > $1.occurrenceCount }

    let totalReports = try await CrashReport.query(on: request.db)
      .filter(\.$app == app.rawValue)
      .count()
    let unsymbolicatedCount = try await CrashReport.query(on: request.db)
      .filter(\.$app == app.rawValue)
      .filter(\.$isSymbolicated == false)
      .count()

    return CrashSummaryResponse(
      groups: responses,
      totalReports: totalReports,
      unsymbolicatedCount: unsymbolicatedCount
    )
  }

  @Sendable
  func updateGroup(_ request: Request) async throws -> CrashGroupResponse {
    let app = try CrashApp(request: request)

    guard
      let id = request.parameters.get("groupID", as: UUID.self),
      let group = try await CrashGroup.find(id, on: request.db),
      group.app == app.rawValue
    else {
      throw Abort(.notFound)
    }

    let payload = try request.content.decode(UpdateCrashGroupRequest.self)
    if let title = payload.title { group.title = title }
    if let severity = payload.severity { group.severity = severity }
    if let affectedVersions = payload.affectedVersions { group.affectedVersions = affectedVersions }
    if let firstSeenVersion = payload.firstSeenVersion { group.firstSeenVersion = firstSeenVersion }
    if let lastSeenVersion = payload.lastSeenVersion { group.lastSeenVersion = lastSeenVersion }
    if let fixPRUrl = payload.fixPRUrl { group.fixPRUrl = fixPRUrl }
    if let fixStatus = payload.fixStatus { group.fixStatus = fixStatus }
    if let analysis = payload.analysis { group.analysis = analysis }
    if let isThirdParty = payload.isThirdParty { group.isThirdParty = isThirdParty }

    try await group.save(on: request.db)

    let count = try await CrashReport.query(on: request.db)
      .filter(\.$crashGroupID == group.requireID())
      .count()

    return try CrashGroupResponse(from: group, occurrenceCount: count)
  }
}

// MARK: - dSYMs

private extension AdminCrashController {

  /// Records where each binary's symbols live. Posted by the build that produced them.
  @Sendable
  func registerDSYMs(_ request: Request) async throws -> HTTPStatus {
    let app = try CrashApp(request: request)
    let payload = try request.content.decode(RegisterDSYMsRequest.self)

    for entry in payload.dsyms {
      let uuid = entry.uuid.uppercased().replacingOccurrences(of: "-", with: "")

      // Re-running a build re-uploads the asset, so the URL can change for a UUID that is
      // otherwise identical. Last write wins rather than a duplicate row.
      if let existing = try await DSYMRecord.query(on: request.db)
        .filter(\.$uuid == uuid)
        .first() {
        existing.app = app.rawValue
        existing.binaryName = entry.binaryName
        existing.arch = entry.arch
        existing.appVersion = entry.appVersion
        existing.buildNumber = entry.buildNumber
        existing.downloadURL = entry.downloadURL
        existing.textVMAddr = entry.textVMAddr
        try await existing.save(on: request.db)
      } else {
        try await DSYMRecord(
          app: app.rawValue,
          uuid: uuid,
          binaryName: entry.binaryName,
          arch: entry.arch,
          appVersion: entry.appVersion,
          buildNumber: entry.buildNumber,
          downloadURL: entry.downloadURL,
          textVMAddr: entry.textVMAddr
        ).save(on: request.db)
      }
    }

    request.logger.info("Registered \(payload.dsyms.count) dSYM(s) for \(app.rawValue)")

    return .ok
  }

  @Sendable
  func listDSYMs(_ request: Request) async throws -> [DSYMResponse] {
    let app = try CrashApp(request: request)

    var query = DSYMRecord.query(on: request.db)
      .filter(\.$app == app.rawValue)

    if let uuid = request.query[String.self, at: "uuid"] {
      query = query.filter(\.$uuid == uuid.uppercased().replacingOccurrences(of: "-", with: ""))
    }
    if let buildNumber = request.query[String.self, at: "buildNumber"] {
      query = query.filter(\.$buildNumber == buildNumber)
    }

    let dsyms = try await query
      .sort(\.$createdAt, .descending)
      .limit(Self.maximumLimit)
      .all()

    var responses = [DSYMResponse]()
    for dsym in dsyms {
      let url = try await DSYMStorage.downloadURL(for: dsym.downloadURL, on: request)
      responses.append(DSYMResponse(from: dsym, downloadURL: url))
    }
    return responses
  }

  /// Where a build should put its dSYM zip. The build uploads with a plain `PUT`, then registers
  /// each binary with the `reference` this returns as its download URL.
  @Sendable
  func dsymUploadURL(_ request: Request) async throws -> DSYMUploadURLResponse {
    let app = try CrashApp(request: request)
    let body = try request.content.decode(DSYMUploadURLRequest.self)

    return try await DSYMStorage.uploadURL(app: app, filename: body.filename, on: request)
  }
}

// MARK: - Storage

/// dSYM zips live in the app's S3 bucket under `dsyms/`, not somewhere public: the repository is
/// open source, but a release page full of symbol archives is clutter nobody asked for, and the
/// bucket already has credentials the backend holds.
///
/// A row's `downloadURL` holds `s3:<key>` for these, and is signed on the way out. Anything else -
/// a URL registered by hand - is passed through untouched.
enum DSYMStorage {

  static let referencePrefix = "s3:"
  static let keyPrefix = "dsyms"

  /// Long enough for a slow upload of a big archive, short enough not to matter if it leaks.
  static let uploadExpiry: TimeAmount = .hours(1)
  static let downloadExpiry: TimeAmount = .hours(2)

  static func uploadURL(app: CrashApp, filename: String, on request: Request) async throws -> DSYMUploadURLResponse {
    guard isValid(filename: filename) else {
      throw Abort(.badRequest, reason: "Invalid filename")
    }

    let key = "\(keyPrefix)/\(app.rawValue)/\(filename)"
    let url = try await sign(key: key, method: .PUT, expires: uploadExpiry, on: request)
    return DSYMUploadURLResponse(uploadURL: url.absoluteString, reference: referencePrefix + key)
  }

  /// The filename becomes part of an S3 key; only let through what a build actually produces.
  static func isValid(filename: String) -> Bool {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
    return !filename.isEmpty
      && filename.count <= 200
      && !filename.contains("..")
      && filename.unicodeScalars.allSatisfy(allowed.contains)
  }

  static func downloadURL(for stored: String, on request: Request) async throws -> String {
    guard stored.hasPrefix(referencePrefix) else { return stored }

    let key = String(stored.dropFirst(referencePrefix.count))
    return try await sign(key: key, method: .GET, expires: downloadExpiry, on: request).absoluteString
  }

  private static func sign(key: String, method: HTTPMethod, expires: TimeAmount, on request: Request) async throws -> URL {
    guard let bucket = Environment.get("S3_BUCKET_NAME") else {
      throw Abort(.serviceUnavailable, reason: "S3 is not configured")
    }

    let s3 = request.sotoS3
    let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key
    guard let url = URL(string: "https://\(bucket).s3.\(s3.region).amazonaws.com/\(encodedKey)") else {
      throw Abort(.internalServerError, reason: "Could not build the S3 URL")
    }

    return try await s3.signURL(url: url, httpMethod: method, expires: expires)
  }
}
