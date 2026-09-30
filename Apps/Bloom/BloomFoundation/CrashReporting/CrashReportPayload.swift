//
//  CrashReportPayload.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-09-29.
//

import Foundation

/// What goes on the wire, and what waits on disk until it can.
///
/// Deliberately not in BloomModel: a report is written to disk by one build and may be sent by
/// the next, so its shape can't move with the rest of the models. This struct and the backend's
/// `SubmitCrashRequest` are the whole contract. Dates must be ISO8601 - encode anything else and
/// every report is rejected with a 400 that says nothing useful.
public struct CrashReportPayload: Codable, Equatable, Sendable {
  let schemaVersion: Int
  let installID: String

  /// Which capture path produced this.
  let source: Source

  /// Stable across capture paths for one crash, so the backend can drop the second arrival.
  let dedupeKey: String?

  let appVersion: String
  let buildNumber: String
  let osVersion: String
  let deviceModel: String

  /// The process that crashed: the app, or one of its extensions.
  let processName: String?

  let exceptionType: String
  let exceptionCode: String?
  let signalName: String?
  let terminationReason: String?
  let crashThread: String

  /// The frames rendered in Apple's `.crash` format, which the symbolicate script reads.
  let stackTrace: String

  /// Apple's own report where there is one. Capped before it gets here.
  let rawReport: String?

  let binaryImages: [BinaryImage]
  let frames: [Frame]

  let crashedAt: Date
}

// MARK: - Source

extension CrashReportPayload {

  enum Source: String, Codable, Equatable, Sendable {
    /// Our signal handler, written inside the crashing process.
    case signal
    /// `NSSetUncaughtExceptionHandler`, before the signal that follows it.
    case nsexception
    /// Apple's own diagnostic, handed to us on a later launch.
    case metrickit
  }
}

// MARK: - Images and frames

extension CrashReportPayload {

  /// One binary as it was loaded at crash time.
  struct BinaryImage: Codable, Equatable, Sendable {
    let name: String

    /// Uppercase, no dashes - the form `dwarfdump --uuid` prints, so the dSYM index matches.
    let uuid: String

    /// Hex, e.g. "0x1023f4000". `atos -l` needs it: without the load address every frame is off
    /// by whatever slide the kernel picked for that launch.
    let loadAddress: String

    let slide: Int?
    let arch: String?
    let isMainExecutable: Bool

    /// Whether this binary is part of the app rather than the system.
    ///
    /// Only the client can tell: it knows which images were loaded out of its own bundle. The
    /// backend groups on the first frame in one of these - the top frame of a signal-caught crash
    /// is always the kernel's trampoline into the handler, which identifies nothing.
    let isAppImage: Bool
  }

  struct Frame: Codable, Equatable, Sendable {
    let index: Int
    let imageName: String?
    let imageUUID: String?

    /// Hex, where the client had an absolute address. MetricKit reports offsets only.
    let address: String?

    /// Distance into the image's text segment. Stable between launches, unlike `address`.
    let offset: Int?

    /// Only where the client already knew it, such as `NSException.callStackSymbols`.
    let symbol: String?
  }
}

// MARK: - Coding

extension CrashReportPayload {

  static func makeEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }

  static func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
}

// MARK: - Developer test

public extension CrashReportPayload {

  /// A report that isn't a crash, for checking the pipeline end to end from the developer screen.
  static func developerTest(configuration: CrashReportingConfiguration = .bloom) -> CrashReportPayload {
    let environment = CrashEnvironment.current
    return CrashReportPayload(
      schemaVersion: configuration.schemaVersion,
      installID: configuration.installID,
      source: .signal,
      dedupeKey: UUID().uuidString,
      appVersion: environment.appVersion,
      buildNumber: environment.buildNumber,
      osVersion: environment.osVersion,
      deviceModel: environment.deviceModel,
      processName: environment.processName,
      exceptionType: "DEVELOPER_TEST",
      exceptionCode: nil,
      signalName: nil,
      terminationReason: "Sent from Developer Settings - not a real crash",
      crashThread: "0",
      stackTrace: "0   \(environment.processName)   0x0 0x0 + 0",
      rawReport: nil,
      binaryImages: [],
      frames: [],
      crashedAt: Date()
    )
  }
}
