import Foundation
@preconcurrency import SwiftData

public enum SchemaV25: VersionedSchema {
  public static let versionIdentifier = Schema.Version(0, 25, 0)

  public static let models: [any PersistentModel.Type] = [
    SchemaV17.BowelMovement.self,
    SchemaV21.ChatMessage.self,
    SchemaV9.FoodItemRecord.self,
    SchemaV9.FoodItemLog.self,
    SchemaV9.FoodItemServing.self,
    SchemaV11.Habit.self,
    SchemaV9.MealRecord.self,
    SchemaV9.MealItemRecord.self,
    SchemaV22.MorningHealthReport.self,
    SchemaV22.MorningHealthInsight.self,
    SchemaV24.Reminder.self,
    SchemaV24.ReminderOccurrence.self,
    SchemaV24.ReminderCompletionRecord.self,
    SchemaV24.ReminderSideEffect.self,
    SchemaV25.TodayContent.self,
    SchemaV25.TodayInsight.self,
    SchemaV19.UserFact.self,
    SchemaV14.WorkoutExercise.self,
    SchemaV14.WorkoutPlan.self,
    SchemaV14.WorkoutSet.self
  ]
}