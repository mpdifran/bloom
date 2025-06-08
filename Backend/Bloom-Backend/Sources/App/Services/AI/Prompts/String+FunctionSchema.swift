//
//  String+FunctionSchema.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-05-23.
//

import Vapor
import BloomModel

extension String {
  enum FunctionSchema { }
}

extension String.FunctionSchema {

  static let logFood: String = """
    Log Food: {
      "name": String, // Required. The name you would give the food. Capitalize using title case.
      "meal": Meal, // Required. The meal you think this food is for. You can use the current time, as well as the type of food to determine this.
      "foodItems": [FoodItem] // Required. A list of individual food items detected.
    }
    
    Meal: An enum with the following types: \(SocketMessage.DetectedFood.Meal.stringCaseList())
    
    FoodItem: {
      "name": String,           // Required. The name of this food item. Capitalize using title case.
      "servingName": String,    // Required. A name for a single serving of the food item. It should not contain the name of the item itself, and should contain a number. It should include the mass of the serving in brackets. Example: "6 crackers (20 g)"
      "servingCount": Double,   // Required. The number of servings of the food item you detect
      "calories": Double,       // Required. The amount of calories, measured in kcal
      "fat": Double?,            // Optional. The amount of fat, measured in g
      "protein": Double?,        // Optional. The amount of protein, measured in g
      "carbohydrates": Double?,  // Optional. The amount of carbohydrates, measured in g
      "saturatedFat": Double?,   // Optional. The amount of saturated fat, measured in g
      "transFat": Double?,       // Optional. The amount of trans fat, measured in g
      "polyunsaturatedFat": Double?, // Optional. The amount of polyunsaturated fat, measured in g
      "monounsaturatedFat": Double?, // Optional. The amount of monounsaturated fat, measured in g
      "fiber": Double?,          // Optional. The amount of fiber, measured in g
      "sugar": Double?,          // Optional. The amount of sugar, measured in g
      "cholesterol": Double?,    // Optional. The amount of cholesterol, measured in mg
      "sodium": Double?,         // Optional. The amount of sodium, measured in mg
      "calcium": Double?,        // Optional. The amount of calcium, measured in mg
      "iron": Double?,           // Optional. The amount of iron, measured in mg
      "potassium": Double?,      // Optional. The amount of potassium, measured in mg
      "magnesium": Double?,      // Optional. The amount of magnesium, measured in mg
      "zinc": Double?,           // Optional. The amount of zinc, measured in mg
      "vitaminA": Double?,       // Optional. The amount of vitamin A, measured in mcg
      "vitaminB6": Double?,      // Optional. The amount of vitamin B6, measured in mg
      "vitaminB12": Double?,     // Optional. The amount of vitamin B12, measured in mcg
      "vitaminC": Double?,       // Optional. The amount of vitamin C, measured in mg
      "vitaminD": Double?,       // Optional. The amount of vitamin D, measured in mcg
      "vitaminE": Double?,       // Optional. The amount of vitamin E, measured in mg
    }
    """

  static let newGoals: String = """
    New Health Goals: {
      "newGoals": [HealthGoal] // Required. A list of goals for the user to add
    }
    
    HealthGoal: {
      "metric": HealthGoalMetric, // Required. The health metric to measure
      "timePeriod": TimePeriod, // Required. The time period of the goal
      "value": Double, // Required. The value of the goal
      "unit": HealthGoalUnit // Required. The unit in which the value is measured in
    }
    
    HealthGoalMetric: An enum with the following cases: \(SuggestedGoal.Metric.stringCaseList())
    
    TimePeriod: An enum with the following cases: \(SuggestedGoal.TimePeriod.stringCaseList())
    
    HealthGoalUnit: An enum with the following cases: \(SuggestedGoal.Unit.stringCaseList())
    """

  static let logWater: String = """
    Log Water: {
      "amount": Double, // Required. The amount of water to log
      "unit": WaterUnit // Required. The unit the value is measured in
    }
    
    WaterUnit: An enum with the following cases: \(SocketMessage.LogWaterConsumption.Unit.stringCaseList())
    """

  static let logBowelMovement: String = """
    Log Bowel Movement: {
      "bristolStoolType": Int,   // Required. The bristol stool type of the bowel movement
      "duration": Duration       // Required. The duration of the bowel movement
    }
    
    Duration: An enum with the following cases: \(SocketMessage.LogBowelMovement.Duration.stringCaseList())
    """

  static let logWeight: String = """
    Log Weight: {
      "value": Double,    // Required. The user's weight
      "unit": WeightUnit  // Required. The unit to measure the weight with
    }

    WeightUnit: An enum with the following cases: \(SocketMessage.LogWeight.Unit.stringCaseList())
    """

  static let logPeriod: String = """
    Log Period: {
      "flow": FlowLevel // Required. The flow level of the period.
    }
    
    FlowLevel: An enum with the following cases: \(SocketMessage.LogPeriod.FlowLevel.stringCaseList())
    """

  static let logBloodPressure: String = """
    Log Blood Pressure: {
      "systolic": Int,   // Required. The systolic measurement of blood pressure.
      "diastolic": Int   // Required. The diastolic measurement of blood pressure.
    }
    """

  static let createWorkoutPlan: String = """
    Create Workout Plan: {
      "title": String,              // Required. The title of the workout plan.
      "summary": String,            // Required. A short summary of the workout and what it will focus on.
      "requiredEquipment": [Equipment], // Required. The list of equipment required for the workout.
      "sets": [WorkoutSet]          // Required. A list of sets. The workout should start with a warm up and end with a cool down.
    }

    Equipment: An enum with the following cases: \(SocketMessage.WorkoutPlan.Equipment.stringCaseList())

    WorkoutSet: {
      "title": String,             // Required. The title of the workout set.
      "focus": String,             // Required. A sentence describing what this set will focus on.
      "numberOfSets": Int?,        // Optional. How many times to repeat this set (usually 3–6).
      "format": Format,            // Required. The format of the set (e.g., amrap, emom, tabata).
      "duration": Double?,         // Optional. Duration in seconds for time‑based formats.
      "appleWorkoutType": AppleWorkoutType, // Required. The Apple workout type for this step.
      "restBetweenExercises": Double?, // Optional. Rest duration in seconds (0 or null if none).
      "exercises": [Exercise]      // Required. The exercises in this set (1–2 exercises typical).
    }

    Format: An enum with the following cases: \(SocketMessage.WorkoutSet.Format.stringCaseList())
  
    AppleWorkoutType: An enum with the following cases: \(SocketMessage.AppleWorkoutType.stringCaseList())

    Exercise: {
      "title": String,             // Required. The name of the exercise.
      "instructions": String,      // Required. A short summary of how to perform the exercise.
      "numberOfReps": Int?,        // Optional. Number of repetitions if applicable.
      "distance": Double?,         // Optional. Distance to cover if applicable.
      "distanceUnit": DistanceUnit?, // Optional. The unit for distance.
      "duration": Double           // Required. Duration in seconds or estimated time to complete.
    }
  
    DistanceUnit: An enum with the following cases: \(SocketMessage.WorkoutExercise.DistanceUnit.stringCaseList())
  """

  static let createReminder: String = """
    Create Reminder: {
      "id": String?,                       // Optional. ID of existing reminder to update. Leave null for new reminders.
      "title": String,                     // Required. Short title for the reminder using title case. Examples: "Take Vitamins", "Log Weight"
      "color": String,                     // Required. A hex color code for the reminder (e.g., "#FF0000").
      "occurrences": [ReminderOccurrence] // Required. When the reminder should occur.
    }

    ReminderOccurrence: {
      "cadenceType": CadenceType,  // Required. How often the reminder repeats.
      "hour": Int,                 // Required. Hour of day in 24-hour format (0-23).
      "minute": Int,               // Required. Minute of the hour (0-59).
      "daysOfWeek": [Weekday]?,    // Optional. Days of week for weekly reminders.
      "dayOfMonth": Int?,          // Optional. Day of month for monthly reminders (1-31).
      "monthOfYear": Month?,       // Optional. Month for yearly reminders.
      "dayOfYear": Int?            // Optional. Day of month for yearly reminders (1-31).
    }

    CadenceType: An enum with the following cases: \(SocketMessage.CadenceType.stringCaseList())
    
    Weekday: An enum with the following cases: \(SocketMessage.Weekday.stringCaseList())
    
    Month: An enum with the following cases: \(SocketMessage.Month.stringCaseList())
    """

  static let deleteReminder: String = """
    Delete Reminder: {
      "reminderID": String // Required. The ID of the reminder to delete.
    }
    """

  static let createUserFact: String = """
    Create User Fact: {
      "facts": [UserFact] // Required. A list of user facts to create and store.
    }
    
    UserFact: {
      "fact": String,        // Required. The user fact to store for future reference.
      "revisitDate": String  // Required. ISO-8601 date when this fact should be revisited (e.g., "2025-07-01T00:00:00Z").
    }
    """

  static let deleteUserFact: String = """
    Delete User Fact: {
      "facts": [DeletedFact] // Required. A list of user facts to delete.
    }
    
    DeletedFact: {
      "id": String,   // Required. The ID of the user fact to delete.
      "fact": String  // Required. The content of the user fact being deleted.
    }
    """
}
