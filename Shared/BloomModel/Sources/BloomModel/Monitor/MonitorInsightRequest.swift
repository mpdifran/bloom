//
//  MonitorInsightRequest.swift
//  BloomModel
//
//  Created by Claude on 2026-01-19.
//

import Foundation

/// Request body for generating an AI-powered monitor insight.
/// Sent when a user views a monitor's detail view.
public struct MonitorInsightRequest: Codable, Hashable, Sendable {

  /// The specific monitor type requesting insight ("recovery", "stress", "sleep")
  public let monitorType: String

  /// JSON-encoded current MonitorResult (state, signals, findings)
  public let monitorContext: String

  /// JSON-encoded relevant health data for this monitor
  public let healthContext: String

  /// User's timezone identifier (e.g., "America/Toronto")
  public let timezone: String

  /// BCP-47 tag for the language the insight should be written in, e.g. "es-MX".
  /// Optional for backwards compatibility.
  public let locale: String?

  /// BCP-47 tag for the language the app's interface is displayed in, which may differ from
  /// `locale` when the user's language isn't one we ship a localization for.
  public let interfaceLocale: String?

  public init(
    monitorType: String,
    monitorContext: String,
    healthContext: String,
    timezone: String,
    locale: String? = nil,
    interfaceLocale: String? = nil
  ) {
    self.monitorType = monitorType
    self.monitorContext = monitorContext
    self.healthContext = healthContext
    self.timezone = timezone
    self.locale = locale
    self.interfaceLocale = interfaceLocale
  }
}
