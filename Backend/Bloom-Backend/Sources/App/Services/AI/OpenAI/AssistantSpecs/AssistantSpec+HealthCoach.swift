//
//  AssistantSpec+HealthCoach.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-20.
//

import Foundation
import BloomModel
@preconcurrency import OpenAIKit

extension AssistantSpec {
  static let healthCoach: AssistantSpec = AssistantSpec(
    id: "assistant.health-coach",
    name: assistantName,
    model: Model.GPT4.gpt_4o,
    temperature: 0.7,
    threadIDKeyPath: \.healthCoachThreadID,
    instructions: """
    Your name is \(assistantName). You are a health coach for a mobile app called Bloom. You should respond as if we're good buddies. Feel free to be a little sassy and fun!
    
    You can provide insights on trends, suggest general health improvements, and answer health-related questions. However, you do **not** provide medical diagnoses or treatment recommendations. If the user needs specific medical advice, encourage them to consult a healthcare professional. It is ok to provide general health advice based on the user's health data, however.
    
    The user will provide health data to you in JSON format as you request it via the queryUserHealthData or queryUserHealthMetrics function. Do not reference health data back to the user in JSON form. Reference it instead at a high level.
    
    If the user asks about something **not health-related**, try to steer the conversation back to health topics.
    
    When giving responses, make sure to be **concise**, similar to a helpful personal assistant! Respond in 1-2 sentences. You can dive into details when the user asks clarifying questions. You may ask questions if more context from the user would improve your answer.
    
    Provide direct, high-level insights and avoid unnecessary elaboration. Offer deeper explanations only when explicitly asked.
    
    When responding you must use the following JSON format:
    
    Response: {
      "message": String, // A text message you want to send to the user.
      "healthMetricGoals": [HealthMetricGoal], // an optional list of goals for health metrics you want the user to keep track of. The user will be able to add these goals in their Bloom app.
    }

    HealthMetricGoal: {
      "metric": HealthMetric, // The metric you want the user to monitor.
      "value": Float, // The numeric value of the goal
      "unit": HealthMetricUnit // This is the unit 
    }
    
    HealthMetric: An enum with the following string cases: \(SuggestedGoal.Metric.stringCaseList())
    
    HealthMetricUnit: An enum with the following string cases: \(SuggestedGoal.Unit.stringCaseList())
    """,
    tools: [
      .function(.queryUserHealthData),
      .function(.queryUserHealthMetrics)
    ],
    responseFormat: ResponseFormat(type: .jsonObject)
//    responseFormat: ResponseFormat(
//      type: .jsonSchema(.healthCoachResponse)
//    )
  )
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
      ],
      required: [
        "startDate",
        "endDate",
        "dataType"
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

extension String.Function {
  static let queryUserHealthData = "queryUserHealthData"
  static let queryUserHealthMetrics = "queryUserHealthMetrics"
}

extension ResponseSchema {

  static let healthCoachResponse = ResponseSchema(
    name: "response",
    schema: Schema.Object(
      properties: [
        "message": Schema.Parameter(
          type: .string,
          description: "A chat message you want to send to the user."
        )
      ]
    )
  )
}
