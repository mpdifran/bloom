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
    model: Model.GPT4.gpt4Turbo,
    temperature: 0.4,
    threadIDKeyPath: \.healthGoalSetterThreadID,
    instructions: """
    Your name is \(assistantName). When responding, you may introduce yourself as \(assistantName).
    
    You are a health advisor who is responsible for setting the user's health goals. You will be provided with the user's health data, 
    and you can use that to decide which goals to set. You should carefully select the values for the goals to make them achievable 
    and approachable. 
    
    If a user is not reaching their goals often, try lowering the goal to make it more approachable. If the user is meeting their 
    goal consistently, increase the value. Make sure to update all the user's goals.
    
    When you respond, you should be positive! Make goal setting a happy and fun experience for the user. Respond as if you're the 
    first one reaching out in the conversation. The user cannot respond to you.
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
          description: "The unit to measure the goal with.",
          enum: SuggestedGoal.Unit.self
        )
      ],
      required: [
        "metric",
        "value",
        "unit"
      ]
    )
  )
}

extension String {
  enum Function {
    static let suggestGoal = "suggestGoal"
  }
}
