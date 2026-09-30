//
//  CrashGrouping.swift
//  Bloom-Backend
//

import Fluent
import Foundation

enum CrashGrouping {

  /// Files a report under a group, creating one if this is the first of its kind.
  ///
  /// Runs twice in a report's life: once on arrival, when the top frame is an address and the
  /// signature can only be coarse, and again after symbolication, when the frame has a name and the
  /// signature is worth something. That is why `CrashGroup` has no stored count.
  static func group(_ report: CrashReport, on db: any Database) async throws {
    let signature = self.signature(for: report)

    let group: CrashGroup
    if let existing = try await CrashGroup.query(on: db)
      .filter(\.$app == report.app)
      .filter(\.$signature == signature)
      .first() {
      if !existing.affectedVersions.contains(report.appVersion) {
        existing.affectedVersions.append(report.appVersion)
      }
      existing.lastSeenVersion = report.appVersion
      existing.lastSeenAt = Date()
      try await existing.save(on: db)
      group = existing
    } else {
      let newGroup = CrashGroup(
        app: report.app,
        signature: signature,
        title: report.exceptionType,
        severity: "unknown",
        affectedVersions: [report.appVersion],
        firstSeenVersion: report.appVersion,
        lastSeenVersion: report.appVersion
      )
      newGroup.lastSeenAt = Date()
      try await newGroup.save(on: db)
      group = newGroup
    }

    report.crashGroupID = try group.requireID()
    try await report.save(on: db)
  }

  /// The signature a report groups under.
  ///
  /// Keyed on the first frame belonging to the app, not the topmost frame: a crash caught by a
  /// signal handler always has the kernel's trampoline on top, so keying on that groups every crash
  /// under `libsystem_platform.dylib` regardless of what actually broke. The client marks which
  /// images are the app's.
  static func signature(for report: CrashReport) -> String {
    let trace = report.symbolicatedTrace ?? report.stackTrace
    let appImageNames = Set(
      (report.binaryImages ?? [])
        .filter { $0.isAppImage == true }
        .map(\.name)
    )

    guard !appImageNames.isEmpty else {
      return CrashSignature.compute(exceptionType: report.exceptionType, stackTrace: trace)
    }

    let appFrames = trace
      .split(whereSeparator: \.isNewline)
      .filter { line in appImageNames.contains { line.contains($0) } }
      .joined(separator: "\n")

    // A crash entirely inside system code - nothing of ours on the stack - still has to go
    // somewhere, so fall back to the whole trace rather than dropping it.
    return CrashSignature.compute(
      exceptionType: report.exceptionType,
      stackTrace: appFrames.isEmpty ? trace : appFrames
    )
  }
}

/// Computes a stable crash signature so identical crashes group together.
///
/// The signature combines the exception type with the first meaningful stack frame, normalized to
/// strip volatile pieces (memory addresses, load offsets, frame indices) that differ between
/// otherwise-identical crashes.
enum CrashSignature {
  static func compute(exceptionType: String, stackTrace: String) -> String {
    let frame = self.normalizedTopFrame(from: stackTrace)
    return "\(exceptionType.trimmingCharacters(in: .whitespaces))|\(frame)"
  }

  /// Returns the first non-empty stack frame with addresses, hex offsets and the leading frame
  /// index removed, collapsing it to `binary symbol`.
  private static func normalizedTopFrame(from stackTrace: String) -> String {
    for rawLine in stackTrace.split(whereSeparator: \.isNewline) {
      let line = rawLine.trimmingCharacters(in: .whitespaces)
      guard !line.isEmpty else { continue }

      var tokens = line.split(separator: " ").map(String.init)

      // Drop a leading frame index (e.g. "0", "12").
      if let first = tokens.first, first.allSatisfy(\.isNumber) {
        tokens.removeFirst()
      }

      // Drop hex addresses (0x...) and bare hex/decimal offsets.
      tokens.removeAll { token in
        token.hasPrefix("0x") || token == "+" || token.allSatisfy(\.isNumber)
      }

      let normalized = tokens.joined(separator: " ").trimmingCharacters(in: .whitespaces)
      if !normalized.isEmpty {
        return normalized
      }
    }
    return "<unknown>"
  }
}
