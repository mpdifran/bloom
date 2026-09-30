//
//  CrashEnvironment.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-09-29.
//

import Foundation

/// What the app and the device were when the crash happened.
///
/// Read at install time and held, because a crash report is assembled at a point where reading
/// the bundle or calling `sysctl` is no longer wise.
struct CrashEnvironment: Sendable {

  let appVersion: String
  let buildNumber: String
  let osVersion: String

  /// The hardware identifier, e.g. "iPhone17,1" - not the marketing name, which the OS will not
  /// tell you.
  let deviceModel: String

  /// The executable's name: "Bloom", or an extension's.
  let processName: String

  static let current = CrashEnvironment()

  init() {
    let info = Bundle.main.infoDictionary
    self.appVersion = info?["CFBundleShortVersionString"] as? String ?? "unknown"
    self.buildNumber = info?["CFBundleVersion"] as? String ?? "unknown"

    // ProcessInfo rather than UIDevice: it's the same on every platform and doesn't need the
    // main actor.
    let version = ProcessInfo.processInfo.operatingSystemVersion
    self.osVersion = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

    self.deviceModel = Self.hardwareModel()
    self.processName = Bundle.main.executableURL?.lastPathComponent ?? ProcessInfo.processInfo.processName
  }

  private static func hardwareModel() -> String {
    var size = 0
    sysctlbyname("hw.machine", nil, &size, nil, 0)

    guard size > 0 else { return "unknown" }

    var bytes = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.machine", &bytes, &size, nil, 0)

    return String(decoding: bytes.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
  }
}
