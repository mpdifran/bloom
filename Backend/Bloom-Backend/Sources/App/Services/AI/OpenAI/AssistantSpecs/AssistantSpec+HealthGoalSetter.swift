//
//  AssistantSpec+HealthGoalSetter.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-20.
//

import Foundation
import BloomModel
@preconcurrency import OpenAIKit

extension AssistantSpec {
  static let healthGoalSetterSpec = AssistantSpec(
    id: "assistant.health-goal-setter",
    name: assistantName,
    model: .GPT5.gpt5Mini,
    temperature: 0.1,
    topP: 0.2,
    threadIDKeyPath: \.healthGoalSetterThreadID,
    instructions: """
    You are \(assistantName), a health advisor. Read the user's health data, detect trends, and suggest or edit achievable goals to improve well-being.
    Adjust goals dynamically based on progress. Use \(String.Function.suggestGoal) for goal suggestions.
    Do not list the goals in your response
    Keep responses short, positive, and engaging.
    Respond as if you're the first one reaching out in the conversation. The user cannot respond to you.
    """,
    tools: [
      .function(.suggestedGoal)
    ]
  )
}

extension Assistant.Tool.Function {
  static let suggestedGoal = Assistant.Tool.Function(
    name: .Function.suggestGoal,
    description: "A function to suggest a goal to the user.",
    parameters: Schema.Object(
      properties: [
        "metric" : Schema.Parameter(
          enum: SuggestedGoal.Metric.self,
          description: "The metric that the goal will be measured by."
        ),
        "value" : Schema.Parameter(
          type: .number,
          description: "The numeric value of the goal."
        ),
        "unit" : Schema.Parameter(
          enum: SuggestedGoal.Unit.self,
          description: "The unit to measure the goal with."
        ),
        "notes" : Schema.Parameter(
          type: .string,
          description: "A short, 1 sentence note about the goal."
        )
      ],
      required: [
        "metric",
        "value",
        "unit",
        "notes"
      ]
    )
  )
}

extension String.Function {
  static let suggestGoal = "suggestGoal"
}
