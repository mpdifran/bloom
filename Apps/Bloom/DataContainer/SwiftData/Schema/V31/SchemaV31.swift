//
//  SchemaV31.swift
//  DataContainer
//
//  Created by Claude on 2026-01-09.
//

import Foundation
@preconcurrency import SwiftData

public enum SchemaV31: VersionedSchema {
  public static let versionIdentifier = Schema.Version(0, 31, 0)

  public static let models: [any PersistentModel.Type] = [
    SchemaV17.BowelMovement.self,
    SchemaV28.ChatMessage.self,
    SchemaV28.ChatConversation.self,
    SchemaV29.FoodItemRecord.self,
    SchemaV29.FoodItemLog.self,
    SchemaV29.FoodItemServing.self,
    SchemaV11.Habit.self,
    SchemaV29.MealRecord.self,
    SchemaV29.MealItemRecord.self,
    SchemaV22.MorningHealthReport.self,
    SchemaV22.MorningHealthInsight.self,
    SchemaV24.Reminder.self,
    SchemaV24.ReminderOccurrence.self,
    SchemaV24.ReminderCompletionRecord.self,
    SchemaV24.ReminderSideEffect.self,
    SchemaV19.UserFact.self,
    SchemaV14.WorkoutExercise.self,
    SchemaV14.WorkoutPlan.self,
    SchemaV14.WorkoutSet.self,
    SchemaV30.BiologicalAgeRecord.self,
    SchemaV31.DailyMetricSample.self
  ]
}
