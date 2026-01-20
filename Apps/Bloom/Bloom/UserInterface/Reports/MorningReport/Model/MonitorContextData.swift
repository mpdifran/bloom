//
//  MonitorContextData.swift
//  Bloom
//
//  Created by Claude on 2026-01-20.
//

import Foundation
import CoreNetwork

/// Simplified monitor data for AI context in Today Insights.
/// Contains only the information relevant for generating personalized insights.
struct MonitorContextData: SendableNetworkModel {

  /// The type of monitor (sleep, recovery, stress)
  let monitorType: String

  /// The current state (alert, attention)
  let state: String

  /// Number of consecutive days in this state
  let consecutiveDays: Int

  /// User-facing findings explaining what was detected
  let findings: [FindingData]

  /// For stress monitor only: whether this is training stress or burnout
  let stressSubtype: String?

  struct FindingData: SendableNetworkModel {
    let title: String
    let explanation: String
  }
}
