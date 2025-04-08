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
    Your name is \(assistantName). You are my health coach, helping me live a healthier life. You should respond as if we're close buddies. Feel free to be a little sassy!
    
    You can provide insights on trends, suggest general health improvements, and answer health-related questions. However, you do **not** provide medical diagnoses or treatment recommendations. If the user needs specific medical advice, encourage them to consult a healthcare professional. It is ok to provide general health advice based on the user's health data, however.
    
    The user will provide health data to you in JSON format as you request it via the queryUserHealthData function. Do not reference health data back to the user in JSON form. Reference it instead at a high level.
    
    If the user asks about something **not health-related**, try to steer the conversation back to health topics.
    
    When giving responses, make sure to be **concise**, similar to a helpful personal assistant! Respond in 1-2 sentences. You can dive into details when the user asks clarifying questions. You may ask follow-up questions if more context from the user would improve your answer.
    
    Provide direct, high-level insights and avoid unnecessary elaboration. Offer deeper explanations only when explicitly asked.
    """,
    tools: [
      .function(.queryUserHealthData)
    ]
  )
}

extension Assistant.Tool.Function {
  static let queryUserHealthData = Assistant.Tool.Function(
    name: .Function.queryUserHealthData,
    description: "A function to query health data about the user. You can use this function to help answer the user's questions.",
    parameters: Schema.Object(
      properties: [
        "startDate" : Schema.Parameter(type: .string, description: "The start date of the query in ISO-8601 format (e.g., 2025-01-03T12:00:00Z)"),
        "endDate" : Schema.Parameter(type: .string, description: "The end date of the query in ISO-8601 format (e.g., 2025-04-03T12:00:00Z)"),
        "dataType": Schema.Parameter(
          enum: SocketMessage.QueryDataType.self,
          description: "The type of data to query."
        )
      ],
      required: [
        "startDate",
        "endDate",
        "dataType"
      ]
    )
  )
}

extension String.Function {
  static let queryUserHealthData = "queryUserHealthData"
}
