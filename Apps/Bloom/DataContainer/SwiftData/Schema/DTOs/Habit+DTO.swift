//
//  Habit+DTO.swift
//  DataContainer
//
//  Created by Mark DiFranco on 2024-10-02.
//

import Foundation
import SwiftData

public struct HabitDTO: Equatable, Sendable {
  public let id: PersistentIdentifier!
  public let targetMetric: TargetMetric
  public let timePeriod: GoalTimePeriod
  public let value: Double
  public let unitString: String
  public let startDate: Date
  public let endDate: Date?
  public let lastNotificationDate: Date?
  public let isSuggested: Bool
  public let isUserEdited: Bool
  public let vitalKind: VitalModel.Kind?
  public let context: String?

  public init(
    id: PersistentIdentifier!,
    targetMetric: TargetMetric,
    timePeriod: GoalTimePeriod,
    value: Double,
    unitString: String,
    startDate: Date,
    endDate: Date?,
    lastNotificationDate: Date?,
    isSuggested: Bool,
    isUserEdited: Bool,
    vitalKind: VitalModel.Kind?,
    context: String?
  ) {
    self.id = id
    self.targetMetric = targetMetric
    self.timePeriod = timePeriod
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

public extension Habit {

  func asDTO() -> HabitDTO {
    HabitDTO(
      id: persistentModelID,
      targetMetric: targetMetric,
      timePeriod: timePeriod,
      value: value,
      unitString: unitString,
      startDate: startDate,
      endDate: endDate,
      lastNotificationDate: lastNotificationDate,
      isSuggested: isSuggested,
      isUserEdited: isUserEdited,
      vitalKind: vitalKind,
      context: context
    )
  }
}
