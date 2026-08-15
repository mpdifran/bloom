//
//  TodayReportRequest.swift
//  bloom-model
//
//  Created by Assistant on 2025-08-27.
//

import Foundation

public struct TodayReportRequest: Codable, Hashable, Sendable {
  public let healthContext: String // JSON string containing health data
  public let currentTime: String // ISO-8601 date string
  public let timezone: String

  /// BCP-47 tag for the language the response should be written in, e.g. "es-MX".
  ///
  /// Optional for backwards compatibility: clients shipped before this existed send nothing, and
  /// the server leaves the language behaviour untouched.
  public let locale: String?

  /// BCP-47 tag for the language the app's interface is displayed in.
  ///
  /// May differ from `locale`: the assistant can write in any language, but the UI is limited to
  /// the localizations we ship. The server tells the model so it names UI labels correctly.
  public let interfaceLocale: String?

  public init(
    healthContext: String,
    currentTime: String,
    timezone: String,
    locale: String? = nil,
    interfaceLocale: String? = nil
  ) {
    self.healthContext = healthContext
    self.currentTime = currentTime
    self.timezone = timezone
    self.locale = locale
    self.interfaceLocale = interfaceLocale
  }
}
