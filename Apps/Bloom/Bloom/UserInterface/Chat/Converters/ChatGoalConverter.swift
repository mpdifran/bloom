//
//  ChatGoalConverter.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-21.
//

import Foundation
import DataContainer
import BloomFoundation
import BloomModel
import HealthKit

private extension Int {
  static let goalHistoryDays: Int = 30
}

final actor ChatGoalConverter {
  static let shared = ChatGoalConverter()

  private let modelActor = HabitModelActor.standard()

  private init() { }
}

extension ChatGoalConverter {

  func convertGoalDataString() async throws -> String {
    let goalsData = await convertGoalData()
    let jsonData = try JSONEncoder.bloomModel.encode(goalsData)
    return String(data: jsonData, encoding: .utf8) ?? "{}"
  }

  func convertGoalData() async -> CurrentGoalsData? {
    do {
      let activeGoals = try await modelActor.fetchActiveHabits()

      var goalSummaries = [GoalSummary]()
      for goal in activeGoals {
        guard let metric = goal.targetMetric.metric else { continue }

        let summary = await GoalSummary(
          metric: metric,
          goal: goal.displayQuantity
        )
        goalSummaries.append(summary)
      }

      return CurrentGoalsData(currentGoals: goalSummaries)
    } catch {
      print(error)
    }
    return nil
  }
}
