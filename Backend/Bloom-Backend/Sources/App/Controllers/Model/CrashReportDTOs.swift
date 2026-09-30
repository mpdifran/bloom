//
//  CrashReportDTOs.swift
//  Bloom-Backend
//

import Foundation
import Vapor

// MARK: - Requests

/// What an app posts when it has a crash to report.
///
/// Kept here rather than in BloomModel: the client's payload type is written to disk before the
/// app dies, and must not change shape with whatever BloomModel looks like in the next build. This
/// struct and the client's `CrashReportPayload` are the contract. Dates are ISO8601.
struct SubmitCrashRequest: Content {
  let schemaVersion: Int
  let installID: String
  let source: String
  let dedupeKey: String?
  let appVersion: String
  let buildNumber: String
  let osVersion: String
  let deviceModel: String
  let processName: String?
  let exceptionType: String
  let exceptionCode: String?
  let signalName: String?
  let terminationReason: String?
  let crashThread: String
  let stackTrace: String
  let rawReport: String?
  let binaryImages: [CrashBinaryImage]?
  let frames: [CrashFrame]?
  let crashedAt: Date
}

/// Sent back for a duplicate rather than an error: a 4xx makes a well-behaved client keep the
/// report and retry it forever.
struct SubmitCrashResponse: Content {
  let id: UUID?
  let deduped: Bool
}

struct SymbolicateCrashRequest: Content {
  let symbolicatedTrace: String
}

struct UpdateCrashGroupRequest: Content {
  let title: String?
  let severity: String?
  let affectedVersions: [String]?
  let firstSeenVersion: String?
  let lastSeenVersion: String?
  let fixPRUrl: String?
  let fixStatus: String?
  let analysis: String?
  let isThirdParty: Bool?
}

/// One dSYM, as the build that produced it describes it.
struct RegisterDSYMRequest: Content {
  let uuid: String
  let binaryName: String
  let arch: String?
  let appVersion: String
  let buildNumber: String
  let downloadURL: String
  let textVMAddr: String?
}

struct RegisterDSYMsRequest: Content {
  let dsyms: [RegisterDSYMRequest]
}

// MARK: - Responses

struct CrashReportResponse: Content {
  let id: UUID
  let app: String
  let installID: String
  let source: String
  let appVersion: String
  let buildNumber: String
  let osVersion: String
  let deviceModel: String
  let processName: String?
  let exceptionType: String
  let exceptionCode: String?
  let signalName: String?
  let terminationReason: String?
  let crashThread: String
  let stackTrace: String
  let symbolicatedTrace: String?
  let crashGroupID: UUID?
  let isSymbolicated: Bool
  let binaryImages: [CrashBinaryImage]?
  let frames: [CrashFrame]?
  let crashedAt: Date
  let createdAt: Date?

  init(from report: CrashReport) throws {
    self.id = try report.requireID()
    self.app = report.app
    self.installID = report.installID
    self.source = report.source
    self.appVersion = report.appVersion
    self.buildNumber = report.buildNumber
    self.osVersion = report.osVersion
    self.deviceModel = report.deviceModel
    self.processName = report.processName
    self.exceptionType = report.exceptionType
    self.exceptionCode = report.exceptionCode
    self.signalName = report.signalName
    self.terminationReason = report.terminationReason
    self.crashThread = report.crashThread
    self.stackTrace = report.stackTrace
    self.symbolicatedTrace = report.symbolicatedTrace
    self.crashGroupID = report.crashGroupID
    self.isSymbolicated = report.isSymbolicated
    self.binaryImages = report.binaryImages
    self.frames = report.frames
    self.crashedAt = report.crashedAt
    self.createdAt = report.createdAt
  }
}

/// A report plus where to find the symbols for it, so the symbolicator needs one call.
struct UnsymbolicatedCrashResponse: Content {
  let report: CrashReportResponse
  let dsyms: [DSYMResponse]
}

struct DSYMResponse: Content {
  let uuid: String
  let binaryName: String
  let arch: String?
  let appVersion: String
  let buildNumber: String
  let downloadURL: String
  let textVMAddr: String?

  /// `downloadURL` is passed in rather than read off the row: a stored `s3:` reference has to be
  /// signed before anyone can fetch it.
  init(from dsym: DSYMRecord, downloadURL: String) {
    self.uuid = dsym.uuid
    self.binaryName = dsym.binaryName
    self.arch = dsym.arch
    self.appVersion = dsym.appVersion
    self.buildNumber = dsym.buildNumber
    self.downloadURL = downloadURL
    self.textVMAddr = dsym.textVMAddr
  }
}

struct DSYMUploadURLRequest: Content {
  /// The zip's name, e.g. "Bloom-3.3.2-412.dSYMs.zip".
  let filename: String
}

struct DSYMUploadURLResponse: Content {
  /// A presigned `PUT` for the zip.
  let uploadURL: String
  /// What to register as each binary's `downloadURL` once the upload is done.
  let reference: String
}

struct CrashGroupResponse: Content {
  let id: UUID
  let app: String
  let signature: String
  let title: String
  let severity: String
  /// Counted from the reports rather than stored; see `CrashGroup`.
  let occurrenceCount: Int
  let affectedVersions: [String]
  let firstSeenVersion: String
  let lastSeenVersion: String
  let fixPRUrl: String?
  let fixStatus: String?
  let analysis: String?
  let isThirdParty: Bool
  let lastSeenAt: Date?
  let createdAt: Date?
  let updatedAt: Date?

  init(from group: CrashGroup, occurrenceCount: Int) throws {
    self.id = try group.requireID()
    self.app = group.app
    self.signature = group.signature
    self.title = group.title
    self.severity = group.severity
    self.occurrenceCount = occurrenceCount
    self.affectedVersions = group.affectedVersions
    self.firstSeenVersion = group.firstSeenVersion
    self.lastSeenVersion = group.lastSeenVersion
    self.fixPRUrl = group.fixPRUrl
    self.fixStatus = group.fixStatus
    self.analysis = group.analysis
    self.isThirdParty = group.isThirdParty
    self.lastSeenAt = group.lastSeenAt
    self.createdAt = group.createdAt
    self.updatedAt = group.updatedAt
  }
}

struct CrashSummaryResponse: Content {
  let groups: [CrashGroupResponse]
  let totalReports: Int
  let unsymbolicatedCount: Int
}
