import Foundation
@preconcurrency import SwiftData

public enum SchemaV19: VersionedSchema {
  public static let versionIdentifier = Schema.Version(0, 19, 0)

  public static let models: [any PersistentModel.Type] = [
    SchemaV17.BowelMovement.self,
    SchemaV15.ChatMessage.self,
    SchemaV9.FoodItemRecord.self,
    SchemaV9.FoodItemLog.self,
    SchemaV9.FoodItemServing.self,
    SchemaV11.Habit.self,
    SchemaV9.MealRecord.self,
    SchemaV9.MealItemRecord.self,
    SchemaV18.Reminder.self,
    SchemaV18.ReminderOccurrence.self,
    SchemaV18.ReminderCompletionRecord.self,
    SchemaV19.UserFact.self,
    SchemaV14.WorkoutExercise.self,
    SchemaV14.WorkoutPlan.self,
    SchemaV14.WorkoutSet.self
  ]
}