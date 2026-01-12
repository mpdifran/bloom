//
//  HistoricalMonitorEvent.swift
//  Bloom
//
//  Created by Claude on 2026-01-12.
//

import Foundation

/// Represents a significant event detected during historical monitor analysis.
/// Used to track state changes and notification triggers over time.
public struct HistoricalMonitorEvent: Identifiable, Sendable, Equatable {
  public let id: UUID
  public let date: Date
  public let monitorType: MonitorType
  public let eventType: EventType
  public let previousState: MonitorStateValue?
  public let newState: MonitorStateValue
  public let confidence: Double
  public let signals: [Signal]
  public let findings: [Finding]
  /// For stress monitor only: whether this is training stress or burnout
  public let stressSubtype: StressSubtype?

  public enum EventType: String, Sendable {
    case stateChange = "State Change"
    case notificationTrigger = "Notification Trigger"
  }

  public init(
    id: UUID = UUID(),
    date: Date,
    monitorType: MonitorType,
    eventType: EventType,
    previousState: MonitorStateValue?,
    newState: MonitorStateValue,
    confidence: Double,
    signals: [Signal],
    findings: [Finding],
    stressSubtype: StressSubtype? = nil
  ) {
    self.id = id
    self.date = date
    self.monitorType = monitorType
    self.eventType = eventType
    self.previousState = previousState
    self.newState = newState
    self.confidence = confidence
    self.signals = signals
    self.findings = findings
    self.stressSubtype = stressSubtype
  }
}
