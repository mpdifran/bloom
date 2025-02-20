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
    model: Model.GPT4.gpt_4o_mini,
    temperature: 1,
    threadIDKeyPath: \.healthGoalSetterThreadID,
    instructions: """
    Your name is \(assistantName). When responding, you may introduce yourself as \(assistantName).
    
    You are a health advisor who is responsible for setting the user's health goals. You will be provided with the user's health data, 
    and you can use that to decide which goals to set. You should carefully select the number of goals and values for the goals to make 
    them achievable and approachable. 
    
    Focus your goal setting on the highest area of concern of the user's health.
    """,
    tools: [
      .function(
        Assistant.Tool.Function(
          name: "suggestGoal",
          description: "A function to suggest a goal to the user.",
          parameters: Assistant.Tool.Function.Parameters(
            properties: [
              "metric" : Assistant.Tool.Function.Parameter(
                type: .string,
                description: "The metric that the goal will be measured by.",
                enum: SuggestedGoal.Metric.self
              ),
              "value" : Assistant.Tool.Function.Parameter(
                type: .number,
                description: "The numeric value of the goal."
              ),
              "unit" : Assistant.Tool.Function.Parameter(
                type: .string,
                description: "The unit to measure the goal with."
              )
            ],
            required: [
              "metric",
              "value",
              "unit"
            ]
          )
        )
      )
    ]
  )
}

struct SuggestGoalArguments: Decodable, Sendable, Equatable {
  let metric: SuggestedGoal.Metric
  let value: Double
  let unit: String
}
