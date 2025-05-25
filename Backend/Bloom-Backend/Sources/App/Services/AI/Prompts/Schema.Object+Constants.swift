//
//  Schema.Object+Constants.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-05-21.
//

import Foundation
import OpenAIKit
import BloomModel

extension Schema.Object {
  static let newGoals = Schema.Object(
    properties: [
      "newGoals" : Schema.Parameter(
        description: "A list of goals for the user to add",
        arrayOf: .object(Schema.Object(
          properties: [
            "metric" : Schema.Parameter(
              enum: SuggestedGoal.Metric.self,
              description: "Which health metric the goal is for"
            ),
            "timePeriod" : Schema.Parameter(
              enum: SuggestedGoal.TimePeriod.self,
              description: "The time period in which the goal must be met"
            ),
            "value": Schema.Parameter(
              type: .number,
              description: "The value of the goal"
            ),
            "unit": Schema.Parameter(
              enum: SuggestedGoal.Unit.self,
              description: "The unit in which the value is measured in"
            )
          ]
        ))
      )
    ]
  )

  static let logFood = Schema.Object(
    properties: [
      "name": Schema.Parameter(type: .string, description: "The name you would give the food. Capitalize using title case."),
      "meal":Schema.Parameter(
        enum: SocketMessage.DetectedFood.Meal.self,
        description: "The meal you think this food is for. You can use the current time, as well as the type of food to determine this."
      ),
      "foodItems": Schema.Parameter(
        description: "A list of individual food items detected.",
        arrayOf: .object(Schema.Object(
          properties: [
            "name": Schema.Parameter(type: .string, description: "The name of this food item. Capitalize using title case."),
            "servingName": Schema.Parameter(type: .string, description: "A name for a single serving of the food item. It should not contain the name of the item itself, and should contain a number. It should include the mass of the serving in brackets. Example: \"6 crackers (20 g)\""),
            "servingCount": Schema.Parameter(type: .number, description: "The number of servings of the food item you detect."),
            "calories": Schema.Parameter(ref: "quantity"),
            "fat": Schema.Parameter(ref: "quantity"),
            "carbohydrates": Schema.Parameter(ref: "quantity"),
            "protein": Schema.Parameter(ref: "quantity"),
            "saturatedFat": Schema.Parameter(ref: "quantity"),
            "transFat": Schema.Parameter(ref: "quantity"),
            "polyunsaturatedFat": Schema.Parameter(ref: "quantity"),
            "monounsaturatedFat": Schema.Parameter(ref: "quantity"),
            "fiber": Schema.Parameter(ref: "quantity"),
            "sugar": Schema.Parameter(ref: "quantity"),
            "cholesterol": Schema.Parameter(ref: "quantity"),
            "sodium": Schema.Parameter(ref: "quantity"),
            "calcium": Schema.Parameter(ref: "quantity"),
            "iron": Schema.Parameter(ref: "quantity"),
            "potassium": Schema.Parameter(ref: "quantity"),
            "magnesium": Schema.Parameter(ref: "quantity"),
            "zinc": Schema.Parameter(ref: "quantity"),
            "vitaminA": Schema.Parameter(ref: "quantity"),
            "vitaminB6": Schema.Parameter(ref: "quantity"),
            "vitaminB12": Schema.Parameter(ref: "quantity"),
            "vitaminC": Schema.Parameter(ref: "quantity"),
            "vitaminD": Schema.Parameter(ref: "quantity"),
            "vitaminE": Schema.Parameter(ref: "quantity")
          ]
        ))
      )
    ],
    references: [
      "quantity" : .quantity
    ]
  )

  static let logWater = Schema.Object(
    properties: [
      "amount" : Schema.Parameter(
        type: .number,
        description: "The amount of water to log"
      ),
      "unit" : Schema.Parameter(
        enum: SocketMessage.LogWaterConsumption.Unit.self,
        description: "The unit the value is measured in"
      )
    ]
  )

  static let logBowelMovement = Schema.Object(
    properties: [
      "bristolStoolType": Schema.Parameter(
        type: .integer,
        description: "The bristol stool type of the bowel movement"
      ),
      "duration": Schema.Parameter(
        enum: SocketMessage.LogBowelMovement.Duration.self,
        description: "The duration of the bowel movement"
      )
    ]
  )

  static let logWeight = Schema.Object(
    properties: [
      "value": Schema.Parameter(
        type: .number,
        description: "The user's weight"
      ),
      "unit": Schema.Parameter(
        enum: SocketMessage.LogWeight.Unit.self,
        description: "The unit to measure the weight with"
      )
    ]
  )

  static let logPeriod = Schema.Object(
    properties: [
      "flow": Schema.Parameter(
        enum: SocketMessage.LogPeriod.FlowLevel.self,
        description: "The flow level of the period."
      )
    ]
  )

  static let logBloodPressure = Schema.Object(
    properties: [
      "systolic": Schema.Parameter(
        type: .integer,
        description: "The systolic measurement of blood pressure"
      ),
      "diastolic": Schema.Parameter(
        type: .integer,
        description: "The diastolic measurement of blood pressure"
      )
    ]
  )

  static let createWorkoutPlan = Schema.Object(
    properties: [
      "title": Schema.Parameter(
        type: .string,
        description: "The title of the workout plan"
      ),
      "summary": Schema.Parameter(
        type: .string,
        description: "A short summary of the workout and what it will focus on."
      ),
      "requiredEquipment": Schema.Parameter(
        description: "The list of equipment required for the workout.",
        arrayOf: .parameter(
          Schema.Parameter(
            enum: SocketMessage.WorkoutPlan.Equipment.self,
            description: "Required equipment."
          )
        )
      ),
      "sets": Schema.Parameter(
        description: "A list of sets in the workout. The workout should start with a warm up, and end with a cool down.",
        arrayOf: .object(
          Schema.Object(
            properties: [
              "title": Schema.Parameter(
                type: .string,
                description: "The title of the workout set."
              ),
              "focus": Schema.Parameter(
                type: .string,
                description: "A sentence describing what this set will focus on."
              ),
              "numberOfSets": Schema.Parameter(
                type: .optionalInteger,
                description: "How many times the set will be repeated by the user. Usually a value between 3 and 6."
              ),
              "format": Schema.Parameter(
                enum: SocketMessage.WorkoutSet.Format.self,
                description: "What format the set will take. Use the format that makes the most sense for the set. AMRAP stands for 'As Many Rounds As Possible', and requires an overll duration. EMOM stands for 'Every Minute on the Minute', and each exercise is performed for 1 minute or less. Tabata is a specific format that requires 20 seconds of work, and 10 seconds of rest. This is repeated 8 times for a total duration of 4 minutes. You can use standard format for a regular set, and warmup/cooldown to start and end the workout."
              ),
              "duration": Schema.Parameter(
                type: .optionalNumber,
                description: "An optional duration of the set in seconds. This should only be provided for formats that are time based."
              ),
              "appleWorkoutType": Schema.Parameter(
                enum: SocketMessage.AppleWorkoutType.self,
                description: "The Apple workout type for this step."
              ),
              "restBetweenExercises": Schema.Parameter(
                type: .optionalNumber,
                description: "The duration of rest between exercises in this set, in seconds. If no rest is necessary, return 0."
              ),
              "exercises": Schema.Parameter(
                description: "The exercises to perform in this set. Each set should have 1 or 2 exercises, but you can add more if appropriate.",
                arrayOf: .object(
                  Schema.Object(
                    properties: [
                      "title": Schema.Parameter(
                        type: .string,
                        description: "The title for the exercise"
                      ),
                      "description": Schema.Parameter(
                        type: .string,
                        description: "A short description of the exercise"
                      ),
                      "numberOfReps": Schema.Parameter(
                        type: .optionalInteger,
                        description: "The number of repetitions of this exercise the user will perform"
                      ),
                      "distance": Schema.Parameter(
                        type: .optionalNumber,
                        description: "A distance to cover, if applicable for this exercise"
                      ),
                      "distanceUnit": Schema.Parameter(
                        optionalEnum: SocketMessage.WorkoutExercise.DistanceUnit.self,
                        description: "The unit to measure the distance in, if applicable"
                      ),
                      "duration": Schema.Parameter(
                        type: .number,
                        description: "The duration for this exercise, or an estimation of how long this exercise will take"
                      )
                    ]
                  )
                )
              )
            ]
          )
        )
      )
    ]
  )
}
