//
//  ExternalHealthMetricPermission.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-04.
//

import SwiftUI

struct ExternalHealthMetricPermission: Identifiable {
  let id: String
  let name: String
  let description: String
}

extension ExternalHealthMetricPermission {
  static let all: [ExternalHealthMetricPermission] = [
    .demographics,
    .goalHistory,
    .activityLevel,
    .bodyComposition,
    .bowelMovements,
    .exerciseEffectiveness,
    .heartHealth,
    .menstrualHealth,
    .sleep,
    .stress
  ]
}

extension ExternalHealthMetricPermission {

  static let demographics = ExternalHealthMetricPermission(
    id: "demographics",
    name: "Demographics",
    description: "Health data such as age, sex, height, and your health goals."
  )

  static let goalHistory = ExternalHealthMetricPermission(
    id: "goal-history",
    name: "Goal History",
    description: "Health data related to historical averages of goals over the preceding 6 months."
  )

  static let activityLevel = ExternalHealthMetricPermission(
    id: "activity-level",
    name: "Activity Level",
    description: "Health data related to your activity level, such as basal and active energy burned."
  )

  static let bodyComposition = ExternalHealthMetricPermission(
    id: "body-composition",
    name: "Body Composition",
    description: "Health data related to your body, such as body mass and body fat percentage."
  )

  static let bowelMovements = ExternalHealthMetricPermission(
    id: "bowel-movements",
    name: "Bowel Movements",
    description: "Health data comprising of bowel movement data, such as date, duration, and Bristol Stool Type."
  )

  static let exerciseEffectiveness = ExternalHealthMetricPermission(
    id: "exercise-effectiveness",
    name: "Exercise Effectiveness",
    description: "Health data related to your heart rate zones, heart rate during workouts, and types of workouts."
  )

  static let heartHealth = ExternalHealthMetricPermission(
    id: "heart-health",
    name: "Heart Health",
    description: "Health data related to your heart, such as VO₂ Max, resting heart rate, and heart rate recovery."
  )

  static let menstrualHealth = ExternalHealthMetricPermission(
    id: "menstrual-health",
    name: "Menstrual Health",
    description: "Health data related to your menstrual cycle, such as your period start date, and menstrual flow levels."
  )

  static let sleep = ExternalHealthMetricPermission(
    id: "sleep",
    name: "Sleep",
    description: "Health data related to your sleep, such as sleep start and end times, duration in sleep phases, sleeping heart rate, respiratory rate, sound levels, and body temperature."
  )

  static let stress = ExternalHealthMetricPermission(
    id: "stress",
    name: "Stress",
    description: "Health data related to your stress, such as heart rate variability and blood pressure."
  )
}
