//
//  CurrentGoalsData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-21.
//

import Foundation
import BloomModel

struct CurrentGoalsData: SendableNetworkModel {
  let currentGoals: [GoalSummary]
}

struct GoalSummary: Codable, Equatable, Sendable {
  let metric: SuggestedGoal.Metric
  let value: Double
  let unit: String
}
