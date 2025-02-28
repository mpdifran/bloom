//
//  GoalLookbackDetails.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-28.
//

import DataContainer
import SwiftData

struct GoalLookbackDetails: Identifiable, Equatable, Sendable {
  var id: PersistentIdentifier { goal.id }

  let goal: HabitDTO
  let goalMetHistory: [HabitGoalMetSample]
}
