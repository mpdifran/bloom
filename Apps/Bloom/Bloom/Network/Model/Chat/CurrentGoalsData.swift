//
//  CurrentGoalsData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-21.
//

import Foundation
import BloomModel

struct CurrentGoalsData: SendableNetworkModel {
  let unitPreferences: UnitPreferences
  let currentGoals: [GoalSummary]
  let metricSummaries: [MetricSummary]
}

extension CurrentGoalsData {
  struct UnitPreferences: SendableNetworkModel {
    let distanceUnit: String
    let liquidVolumeUnit: String
    let weightUnit: String
  }
}

struct GoalSummary: SendableNetworkModel {
  let metric: SuggestedGoal.Metric
  let history: [GoalHistory]
}

extension GoalSummary {
  struct GoalHistory: SendableNetworkModel {
    let goal: String
    let lastSevenDaysGoalMet: [String]
  }
}

struct MetricSummary: SendableNetworkModel {
  let metric: SuggestedGoal.Metric
  let sevenDayAverage: String
  let thirtyDayAverage: String
  let sixtyDayAverage: String
}
