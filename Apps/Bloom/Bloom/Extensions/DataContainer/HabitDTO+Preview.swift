//
//  HabitDTO+Preview.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-26.
//

import DataContainer

extension HabitDTO {
  enum Preview { }
}

extension HabitDTO.Preview {

  static let steps = HabitDTO(
    id: nil,
    targetMetric: .stepCount,
    timePeriod: .daily,
    value: 5000,
    unitString: "count",
    startDate: Date().addingTimeInterval(604_800),
    endDate: nil,
    lastNotificationDate: nil,
    isSuggested: false,
    isUserEdited: false,
    vitalKind: nil,
    context: "Getting more steps in can help keep your heart healthy."
  )

  static let heartRateZone5 = HabitDTO(
    id: nil,
    targetMetric: .targetHeartRateZone5,
    timePeriod: .daily,
    value: 15,
    unitString: "min",
    startDate: Date().addingTimeInterval(604_800),
    endDate: nil,
    lastNotificationDate: nil,
    isSuggested: false,
    isUserEdited: false,
    vitalKind: nil,
    context: "Extend your cardio by spending more time in Zone 5."
  )
}
