//
//  CrashReportingConfiguration.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-09-29.
//

import Foundation

/// Everything the crash reporter needs to know about the process it's running in.
///
/// Ported from AirChat's reporter. This is the one file in `CrashReporting` that knows Bloom
/// exists; nothing else in the folder reaches for a controller, a model or a bundle key.
public struct CrashReportingConfiguration: Sendable {

  /// Where reports go. The path is `v1/apps/<app>/crashes`. Nil in a process that has no way to
  /// know it - the Screen Time extensions - which only queue reports for the app to send.
  public let baseURL: URL?

  /// Which app the backend files these under: the iOS app and its extensions are `bloom`, the
  /// watch app and its widgets are `bloom-watch`.
  public let app: String

  /// Sent in `X-Crash-Ingest-Key`.
  ///
  /// **This is not a secret.** It ships inside the app binary, where anyone willing to run
  /// `strings` can read it. It keeps crawlers and idle scanners out of the crash table; the
  /// server's rate limits are what actually protect it. Never put an admin secret here.
  public let ingestKey: String

  /// The payload shape the backend is told to expect. Bump it when the payload changes in a way
  /// an older backend could not read.
  public let schemaVersion: Int

  /// Identifies this install, never the person using it. See `CrashInstallIdentifier`.
  public let installID: String

  /// Whether this process sends what's queued. Only the apps do: an extension can die before a
  /// request finishes, and the Screen Time ones have no network to speak of.
  public let uploadsReports: Bool

  /// Whether this process subscribes to MetricKit. The app only - MetricKit reports on the app
  /// that subscribed, and isn't available on watchOS at all.
  public let collectsMetricKit: Bool
}

// MARK: - Bloom

public extension CrashReportingConfiguration {

  static let bloom: CrashReportingConfiguration = {
    let isExtension = Bundle.main.bundleURL.pathExtension == "appex"

    #if os(watchOS)
    let app = "bloom-watch"
    let collectsMetricKit = false
    #else
    let app = "bloom"
    let collectsMetricKit = !isExtension
    #endif

    return CrashReportingConfiguration(
      baseURL: resolvedBaseURL,
      app: app,
      ingestKey: "bck_5c1e8b2f7d9a4e06b3f1c8d2a7e94b50",
      schemaVersion: 1,
      installID: CrashInstallIdentifier.current,
      uploadsReports: !isExtension,
      collectsMetricKit: collectsMetricKit
    )
  }()

  /// The same host the rest of the app talks to, honouring the developer override `APIHost` keeps
  /// in the app group - so a crash can be round-tripped against a local backend.
  private static var resolvedBaseURL: URL? {
    let defaults = UserDefaults.groupIfAvailable
    if defaults?.bool(forKey: "APIHost.overrideEnabled") == true,
       let override = defaults?.string(forKey: "APIHost.base"),
       !override.isEmpty,
       let url = URL(string: override) {
      return url
    }

    guard let urlString = Bundle.main.object(forInfoDictionaryKey: "BLOOM_BASE_URL") as? String else {
      return nil
    }
    return URL(string: urlString.replacingOccurrences(of: "\\", with: ""))
  }
}

// MARK: - Install identifier

/// A UUID made on first launch and kept in the app group, so the app and its extensions report
/// as one install.
///
/// Deliberately not the user's ID or anything synced: that would make crash reports linked to a
/// user, and the App Store privacy answer would have to say so. This only exists so a crash loop
/// on one device can be rate limited without knowing who anyone is.
enum CrashInstallIdentifier {

  private static let key = "CrashReporting.installID"

  static var current: String {
    let defaults = UserDefaults.groupIfAvailable ?? .standard
    if let existing = defaults.string(forKey: key) {
      return existing
    }

    let identifier = UUID().uuidString
    defaults.set(identifier, forKey: key)
    return identifier
  }
}

// MARK: - Settings

public extension String {
  /// Whether crash reports are collected and sent. Kept in the app group so the extensions honour
  /// it too; defaults to on.
  static let crashReportingEnabledKey = "CrashReporting.enabled"
}

extension UserDefaults {

  /// The app group's defaults, or nil in a process whose Info.plist doesn't name the group.
  ///
  /// `UserDefaults.group` would `fatalError` there instead - fine for app code, not for a crash
  /// reporter, which must never be the thing that crashes.
  static var groupIfAvailable: UserDefaults? {
    guard let suiteName = Bundle.main.object(forInfoDictionaryKey: "BLOOM_APP_GROUP_ID") as? String else {
      return nil
    }
    return UserDefaults(suiteName: suiteName)
  }
}
