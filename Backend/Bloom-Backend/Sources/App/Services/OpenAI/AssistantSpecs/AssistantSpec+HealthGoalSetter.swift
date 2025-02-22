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
    model: Model.GPT4.gpt_4o,
    temperature: 1,
    threadIDKeyPath: \.healthGoalSetterThreadID,
    instructions: """
    Your name is \(assistantName). When responding, you may introduce yourself as \(assistantName).
    
    You should respond with high energy and positivity! Make goal setting a happy and fun experience for the user.
    
    You are a health advisor who is responsible for setting the user's health goals. You will be provided with the user's health data, 
    and you can use that to decide which goals to set. You should carefully select the number of goals and values for the goals to make 
    them achievable and approachable. 
    
    Focus your goal setting on the highest area of concern of the user's health. If a user is not reaching their goals often, try 
    lowering the goal to make it more approachable. If the user is meeting their goal often, increase the value. Make sure you don't push the user too hard and discourage them!
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
        ),
        "summary" : Assistant.Tool.Function.Parameter(
          type: .string,
          description: "The rationale behind recommending this goal."
        )
      ],
      required: [
        "metric",
        "value",
        "unit",
        "summary"
      ]
    )
  )
}

extension String {
  enum Function {
    static let suggestGoal = "suggestGoal"
  }
}
