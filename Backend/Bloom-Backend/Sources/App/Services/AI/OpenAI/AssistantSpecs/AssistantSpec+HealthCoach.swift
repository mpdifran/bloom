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
    model: Model.GPT4.gpt_4o,
    threadIDKeyPath: \.healthCoachThreadID,
    instructions: """
    Your name is \(assistantName). You are a health coach for a mobile app called Bloom. You should respond as if we're good buddies. Feel free to be a little sassy and fun!
    
    Think step-by-step. Make sure to incorporate the user's personal data in your responses. You can provide insights on trends, suggest general health improvements, and answer health-related questions. However, you do **not** provide medical diagnoses or treatment recommendations. If the user needs specific medical advice, encourage them to consult a healthcare professional. It is ok to provide general "best practice" health advice based on the user's health data, however.
    
    You can help the user log data to Bloom, like water consumption, food logs, etc. The user will be presented the data, with a button to log it if they want.
    
    The user will provide health data to you in JSON format as you request it via the queryUserHealthData or queryUserHealthMetrics function. Do not reference health data back to the user in JSON form. Reference it instead at a high level.
    
    If the user asks about something **not health-related**, try to steer the conversation back to health topics.
    
    Reply in plain text when no function is needed.
    
    When giving responses, you can dive into details when the user asks clarifying questions. You may ask questions if more context from the user would improve your answer. Offer deeper explanations only when explicitly asked.
    """,
    tools: [
      .function(.queryUserHealthData),
      .function(.queryUserHealthMetrics),
      .function(.setGoals),
      .function(.logFood),
      .function(.logWater),
      .function(.logWeight),
      .function(.logBloodPressure),
      .function(.logBowelMovement)
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
  static let queryUserHealthMetrics = "queryUserHealthMetrics"
}

extension Assistant.Tool.Function {
  static let queryUserHealthData = Assistant.Tool.Function(
    name: .Function.queryUserHealthData,
    description: "A function to query health data about the user. You can use this function to help answer the user's questions. Some data may be missing if the user hasn't recorded it.",
    parameters: Schema.Object(
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

  static let queryUserHealthMetrics = Assistant.Tool.Function(
    name: .Function.queryUserHealthMetrics,
    description: "A function to query the user's health metrics for a given date range. Some data may be missing if the user hasn't recorded it.",
    parameters: Schema.Object(
      properties: [
        "startDate" : Schema.Parameter(type: .string, description: "The start date of the query in ISO-8601 format (e.g., 2025-01-03T12:00:00Z)"),
        "endDate" : Schema.Parameter(type: .string, description: "The end date of the query in ISO-8601 format (e.g., 2025-04-03T12:00:00Z)"),
        "healthMetric": Schema.Parameter(
          enum: SuggestedGoal.Metric.self,
          description: "A health metric to query historical data for. Either specify this or dataType, but not both."
        )
      ]
    )
  )
}

// MARK: Write Data to Client

extension String.Function {
  static let setGoals = "setGoals"
  static let logFood = "logFood"
  static let logWater = "logWater"
  static let logBowelMovement = "logBowelMovement"
  static let logWeight = "logWeight"
  static let logBloodPressure = "logBloodPressure"
}

extension Assistant.Tool.Function {
  static let setGoals = Assistant.Tool.Function(
    name: .Function.setGoals,
    description: "Can be used to modify the user's goals. They will be presented with them, and will first have to approve them before they're saved in Bloom",
    parameters: Schema.Object(
      properties: [
        "newGoals" : Schema.Parameter(
          description: "A list of goals for the user to add",
          arrayOf: Schema.Object(
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
          )
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
        "foodItems": Schema.Parameter(
          description: "A list of individual food items detected.",
          arrayOf: Schema.Object(
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
          )
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
}
