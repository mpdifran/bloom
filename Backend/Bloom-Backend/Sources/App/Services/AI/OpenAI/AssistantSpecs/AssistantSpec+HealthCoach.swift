//
//  AssistantSpec+HealthCoach.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-20.
//

import Foundation
import BloomModel
@preconcurrency import OpenAIKit

// MARK: - AssistantSpec

extension AssistantSpec {
  static let healthCoach: AssistantSpec = AssistantSpec(
    id: "assistant.health-coach",
    name: assistantName,
    model: .GPT4.gpt_4o_mini,
    threadIDKeyPath: \.healthCoachThreadID,
    instructions: """
    Your name is \(assistantName). You are a health coach for a mobile app called Bloom. You’re here to support the user like a good friend — feel free to be a little sassy and fun! You can respond to the user in a similar way to how they respond to you.
    
    Use the user’s personal health data to offer friendly insights, track trends, and suggest general improvements. You may discuss best practices based on their data but do not offer medical diagnoses or treatment recommendations. If specific medical advice is needed, encourage the user to speak to a healthcare professional.
    
    When the user is asking something about their specific health data, you must query the data using \(String.Function.queryUserHealthData). When you do this, never show or reference raw JSON — refer to the data conversationally.
    
    If the user shows you a picture of food, you can automatically log it for them using \(String.Function.logFood). The data you pass here will appear in the chat history for the user.
    
    If the user indicates that they've consumed water, or will consume water, you can use \(String.Function.logWater). For example, they may say "I drank a glass of water" or send you a picture of a water bottle.
    
    If the user sends you their weight, or a photo of their scale, you can log their weight for them using \(String.Function.logWeight).
    
    If the user tells you they had a bowel movement or poop, or sends you a photo of it, you can log it using \(String.Function.logBowelMovement).
    
    If the user tells you thier blood pressure, log it with \(String.Function.logBloodPressure).
    
    If the user tells you they had their period, or the ask you to log it, and they're female, use \(String.Function.logPeriod). You may ask them the flow level if you are unsure.
    
    If the user is interested in tracking progress towards a health goal, you can use \(String.Function.setGoals) to configure it on their behalf. When selecting goals to set for the user, you can first read their health data using \(String.Function.queryUserHealthData). For example, if the user wants to increase their vO2 Max, you can set a weekly cardioDuration goal. You must use this function if you are providing goals to the user.
    
    When the user asks for a workout plan or stretching routine, you can provide one using \(String.Function.createWorkoutPlan). When providing a workout plan, make sure to include both a warm-up and cooldown set. Use multiple sets for the core of the exercise to differentiate between disparate sections. For a stretch routine, you do not need a warm up or cool down. When you call this function, the data will be displayed to the user in the chat. You do not need to elaborate on the plan in your response.
    
    You’re also here for broader support: physical health, mental health, feelings, thoughts, and general well-being — all are fair game. Be casual, curious, and supportive.

    Ask follow-up questions when more context would improve your advice, and only go into detail when the user asks for it.
    """,
    tools: [
      .function(.queryUserHealthData),
      .function(.setGoals),
      .function(.logFood),
      .function(.logWater),
      .function(.logWeight),
      .function(.logPeriod),
      .function(.logBloodPressure),
      .function(.logBowelMovement),
      .function(.createWorkoutPlan)
    ],
    responseFormat: ResponseFormat(type: .text)
  )
}

/*
 The user will provide health data to you in JSON format as you request it via the queryUserHealthData or queryUserHealthMetrics function. Do not reference health data back to the user in JSON form. Reference it instead at a high level.
 */

// MARK: - Functions

// MARK: Query Functions

extension String.Function {
  static let queryUserHealthData = "queryUserHealthData"
}

extension Assistant.Tool.Function {
  static let queryUserHealthData = Assistant.Tool.Function(
    name: .Function.queryUserHealthData,
    description: "A function to query health data about the user. You can use this function to help answer the user's questions. You are allowed to include multiple data types to get a better picture of the user's health. Some data may be missing if the user hasn't recorded it.",
    parameters: Schema.Object(
      properties: [
        "queries" : Schema.Parameter(
          description: "A list of user health data queries you would like to perform.",
          arrayOf: .object(
            Schema.Object(
              properties: [
                "startDate" : Schema.Parameter(type: .string, description: "The start date of the query in ISO-8601 format (e.g., 2025-01-03T12:00:00Z)"),
                "endDate" : Schema.Parameter(type: .string, description: "The end date of the query in ISO-8601 format (e.g., 2025-04-03T12:00:00Z)"),
                "dataType": Schema.Parameter(
                  enum: SocketMessage.QueryDataType.self,
                  description: "The type of health data to query"
                )
              ]
            )
          )
        )
      ]
    )
  )
}

// MARK: Write Data to Client

extension String.Function {
  static let setGoals = "setGoals"
  static let logHealthData = "logHealthData"
  static let logFood = "logFood"
  static let logWater = "logWater"
  static let logBowelMovement = "logBowelMovement"
  static let logWeight = "logWeight"
  static let logPeriod = "logPeriod"
  static let logBloodPressure = "logBloodPressure"
  static let createWorkoutPlan = "createWorkoutPlanOrStretchRoutine"
}

extension Assistant.Tool.Function {
  static let setGoals = Assistant.Tool.Function(
    name: .Function.setGoals,
    description: "Can be used to modify the user's goals. They will be presented with them, and will first have to approve them before they're saved in Bloom",
    parameters: Schema.Object(
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
  )

  static let logHealthData = Assistant.Tool.Function(
    name: .Function.logHealthData,
    description: "You can use this function to log health data on behalf of the user. This function supports logging food, water intake, bowel movements, weight, blood pressure, and periods.",
    parameters: Schema.Object(
      properties: [
        "data": Schema.Parameter(
          description: "The health data to log. Select the kind of data to log, and only populate in the corresponding object",
          arrayOf: .object(
            Schema.Object(
              properties: [
                "kind": Schema.Parameter(enum: SocketMessage.LogKind.self, description: "The kind of data to log"),
                "logWater": Schema.Parameter(ref: "logWater"),
                "logBowelMovements": Schema.Parameter(ref: "logBowelMovements"),
                "logWeight": Schema.Parameter(ref: "logWeight"),
                "logBloodPressure": Schema.Parameter(ref: "logBloodPressure"),
                "logPeriod": Schema.Parameter(ref: "logPeriod"),
                "logFood": Schema.Parameter(ref: "logFood"),
              ]
            )
          )
        )
      ],
      references: [
        "logFood": Schema.Object(
          properties: [
            "name": Schema.Parameter(type: .string, description: "The name you would give the food."),
            "meal":Schema.Parameter(
              enum: SocketMessage.DetectedFood.Meal.self,
              description: "The meal you think this food is for. You can use the current time, as well as the type of food to determine this."
            ),
            "foodItems": Schema.Parameter(
              description: "A list of individual food items detected.",
              arrayOf: .object(Schema.Object(
                properties: [
                  "name": Schema.Parameter(type: .string, description: "The name of this food item"),
                  "servingName": Schema.Parameter(type: .string, description: "A name for a single serving of the food item. It should not contain the name of the item itself, and should contain a number."),
                  "servingValue": Schema.Parameter(ref: "quantity"),
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
        ),
        "logWater": Schema.Object(
          properties: [
            "amount": Schema.Parameter(
              type: .number,
              description: "The amount of water."
            ),
            "unit": Schema.Parameter(
              enum: SocketMessage.LogWaterConsumption.Unit.self,
              description: "The unit to measure the water in"
            )
          ]
        ),
        "logBowelMovements": Schema.Object(
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
        ),
        "logPeriod": Schema.Object(
          properties: [
            "flow": Schema.Parameter(
              enum: SocketMessage.LogPeriod.FlowLevel.self,
              description: "The flow level of the period"
            )
          ]
        ),
        "logWeight": Schema.Object(
          properties: [
            "value": Schema.Parameter(
              type: .number,
              description: "The value of the user's weight"
            ),
            "unit": Schema.Parameter(
              enum: SocketMessage.LogWeight.Unit.self,
              description: "The unit to measure the weight with"
            )
          ]
        ),
        "logBloodPressure": Schema.Object(
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
      ]
    )
  )

  static let logFood = Assistant.Tool.Function(
    name: .Function.logFood,
    description: "This can be used to log food items for the user",
    parameters: Schema.Object(
      properties: [
        "name": Schema.Parameter(type: .string, description: "The name you would give the food."),
        "meal":Schema.Parameter(
          enum: SocketMessage.DetectedFood.Meal.self,
          description: "The meal you think this food is for. You can use the current time, as well as the type of food to determine this."
        ),
        "foodItems": Schema.Parameter(
          description: "A list of individual food items detected.",
          arrayOf: .object(Schema.Object(
            properties: [
              "name": Schema.Parameter(type: .string, description: "The name of this food item"),
              "servingName": Schema.Parameter(type: .string, description: "A name for a single serving of the food item. It should not contain the name of the item itself, and should contain a number."),
              "servingValue": Schema.Parameter(ref: "quantity"),
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
  )

  static let logWater = Assistant.Tool.Function(
    name: .Function.logWater,
    description: "This can be used to log water for the user",
    parameters: Schema.Object(
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
  )

  static let logBowelMovement = Assistant.Tool.Function(
    name: .Function.logBowelMovement,
    description: "This can be used to log a bowel movement for the user",
    parameters: Schema.Object(
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
  )

  static let logWeight = Assistant.Tool.Function(
    name: .Function.logWeight,
    description: "This can be used to log the user's weight",
    parameters: Schema.Object(
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
  )

  static let logPeriod = Assistant.Tool.Function(
    name: .Function.logPeriod,
    description: "This can be used to log a period on behalf of the user. Only use this function for female users.",
    parameters: Schema.Object(
      properties: [
        "flow": Schema.Parameter(
          enum: SocketMessage.LogPeriod.FlowLevel.self,
          description: "The flow level of the period."
        )
      ]
    )
  )

  static let logBloodPressure = Assistant.Tool.Function(
    name: .Function.logBloodPressure,
    description: "This can be used to log the user's blood pressure",
    parameters: Schema.Object(
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
  )

  static let createWorkoutPlan = Assistant.Tool.Function(
    name: .Function.createWorkoutPlan,
    description: "This can be used to create a workout plan for the user to perform.",
    parameters: Schema.Object(
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
  )
}
