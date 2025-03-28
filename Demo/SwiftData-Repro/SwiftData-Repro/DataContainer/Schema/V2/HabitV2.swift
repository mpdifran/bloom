//
//  HabitV2.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-02.
//

import SwiftUI
import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV2 {
  @Model
  public final class Habit: Identifiable, Hashable {
    public var rawTargetMetric: String = ""
    public var value: Double = 0
    public var unitString: String = ""
    public var startDate: Date = Date.now
    public var endDate: Date? = nil
    public var lastNotificationDate: Date? = nil
    public var isSuggested: Bool = false
    public var isUserEdited: Bool = false
    public var vitalKind: VitalModel.Kind?
    public var context: String?

    public init(
      targetMetric: TargetMetric,
      value: Double,
      unitString: String,
      startDate: Date,
      endDate: Date? = nil,
      lastNotificationDate: Date? = nil,
      isSuggested: Bool,
      isUserEdited: Bool,
      vitalKind: VitalModel.Kind? = nil,
      context: String? = nil
    ) {
      self.rawTargetMetric = targetMetric.rawValue
      self.value = value
      self.unitString = unitString
      self.startDate = startDate
      self.endDate = endDate
      self.lastNotificationDate = lastNotificationDate
      self.isSuggested = isSuggested
      self.isUserEdited = isUserEdited
      self.vitalKind = vitalKind
      self.context = context
    }
  }
}

public extension SchemaV2.Habit {

  var targetMetric: TargetMetric {
    TargetMetric(rawValue: rawTargetMetric) ?? .none
  }
}

public enum TargetMetric: String, Identifiable, Codable, CaseIterable, Sendable {
  public var id: Self { self }

  case none
  case calories
  case proteinIntake
  case waterIntake
  case fiberIntake
  case timeInDaylight
  case meditationMinutes
  case exerciseMinutes
  case stepCount
  case walkingRunningDistance
  case runDistance
  case runDuration
  case bikeDistance
  case bikeDuration
  case mobilityAndFlexibilityDuration
  case strengthTrainingDuration
  case cardioDuration
  case highIntensityIntervalTrainingDuration
  case targetHeartRateZone1
  case targetHeartRateZone2
  case targetHeartRateZone3
  case targetHeartRateZone4
  case targetHeartRateZone5
}

public extension TargetMetric {
  enum MeasurementStyle: String, Identifiable, Codable, CaseIterable, Sendable {
    public var id: Self { self }

    case minimum
    case range
  }
}
