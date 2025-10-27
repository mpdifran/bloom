//
//  VitalType.swift
//  Bloom
//
//  Created by Claude Code on 2025-10-23.
//

import AppIntents
import Foundation

enum VitalType: String, AppEnum {
  case sleepQuality
  case activityLevel
  case heartHealth
  case bodyComposition
  case stressLevels
  case nutrition
  case exerciseEffectiveness
  case cycleTracking
  case bowelMovements

  nonisolated(unsafe) static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Vital")

  nonisolated(unsafe) static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
    .sleepQuality: DisplayRepresentation(
      title: "Sleep Quality",
      image: DisplayRepresentation.Image(systemName: "moon.zzz.fill")
    ),
    .activityLevel: DisplayRepresentation(
      title: "Activity Level",
      image: DisplayRepresentation.Image(systemName: "figure.tennis")
    ),
    .heartHealth: DisplayRepresentation(
      title: "Heart Health",
      image: DisplayRepresentation.Image(systemName: "heart.fill")
    ),
    .bodyComposition: DisplayRepresentation(
      title: "Body Composition",
      image: DisplayRepresentation.Image(systemName: "gauge.with.needle")
    ),
    .stressLevels: DisplayRepresentation(
      title: "Stress Levels",
      image: DisplayRepresentation.Image(systemName: "bolt.fill")
    ),
    .nutrition: DisplayRepresentation(
      title: "Nutrition",
      image: DisplayRepresentation.Image(systemName: "fork.knife")
    ),
    .exerciseEffectiveness: DisplayRepresentation(
      title: "Exercise Effectiveness",
      image: DisplayRepresentation.Image(systemName: "figure.mixed.cardio")
    ),
    .cycleTracking: DisplayRepresentation(
      title: "Cycle Tracking",
      image: DisplayRepresentation.Image(systemName: "circle.dotted.and.circle")
    ),
    .bowelMovements: DisplayRepresentation(
      title: "Bowel Movements",
      image: DisplayRepresentation.Image(systemName: "toilet.fill")
    )
  ]

  var urlPath: String {
    switch self {
    case .sleepQuality:
      return "vital/sleep-quality"
    case .activityLevel:
      return "vital/activity-level"
    case .heartHealth:
      return "vital/heart-health"
    case .bodyComposition:
      return "vital/body-composition"
    case .stressLevels:
      return "vital/stress-levels"
    case .nutrition:
      return "vital/nutrition"
    case .exerciseEffectiveness:
      return "vital/exercise-effectiveness"
    case .cycleTracking:
      return "vital/cycle-tracking"
    case .bowelMovements:
      return "vital/bowel-movements"
    }
  }
}
