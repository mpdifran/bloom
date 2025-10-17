//
//  CurrentGoalsData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-21.
//

import Foundation
import BloomModel

public struct CurrentGoalsData: SendableNetworkModel {
  public let currentGoals: [GoalSummary]

  public init(currentGoals: [GoalSummary]) {
    self.currentGoals = currentGoals
  }
}

public struct GoalSummary: SendableNetworkModel {
  public let metric: SuggestedGoal.Metric
  public let goal: String

  public init(metric: SuggestedGoal.Metric, goal: String) {
    self.metric = metric
    self.goal = goal
  }
}
