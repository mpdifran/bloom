//
//  ResponseSchema+HealthReport.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-07-23.
//

import Foundation
import BloomModel
@preconcurrency import OpenAIKit

extension ResponseSchema {
  
  static let todayAI = ResponseSchema(
    name: "todayAI",
    schema: Schema.Object(
      properties: [
        "summary": Schema.Parameter(
          type: .string,
          description: "One sentence describing how the user is feeling today, based on their health data from yesterday."
        ),
        "budState": Schema.Parameter(
          enum: TodayReportResponse.BudState.self,
          description: "A state for Bud that reflects the user's feelings described in the summary parameter above."
        ),
        "todaysAdvice": Schema.Parameter(
          type: .string,
          description: "Focused health advice based on the user's health data from yesterday. This should be a single thing the user should focus on today."
        ),
        "insights": Schema.Parameter(
          description: "A list of key health insights ordered by priority (highest to lowest). For goals, only comment on them if the user is falling behind for the time period. Only comment on things of importance.",
          arrayOf: Schema.Item.object(
            Schema.Object(
              properties: [
                "title": Schema.Parameter(
                  type: .string,
                  description: "A concise title for the insight."
                ),
                "body": Schema.Parameter(
                  type: .string,
                  description: "The detailed insight content."
                ),
                "priority": Schema.Parameter(
                  type: .integer,
                  description: "Priority from 1-10, where 10 is highest priority."
                )
              ]
            )
          )
        ),
        "sleepDetails": Schema.Parameter(
          type: .optionalString,
          description: "A summary of the user's recent sleep patterns with specific insights and recommendations. Optional - only include if sleep data is available."
        ),
        "tonightsSleepRecommendations": Schema.Parameter(
          type: .string,
          description: "Specific recommendations to improve tonight's sleep based on today's activities and recent sleep patterns."
        ),
        "windDownStartHour": Schema.Parameter(
          type: .optionalInteger,
          description: "Recommended bedtime wind down start hour (0-23) in user's timezone to restrict phone usage for optimal sleep."
        ),
        "windDownStartMinute": Schema.Parameter(
          type: .optionalInteger,
          description: "Recommended bedtime wind down start minute (0-59)."
        ),
        "windDownEndHour": Schema.Parameter(
          type: .optionalInteger,
          description: "Recommended bedtime wind down end hour (0-23) in user's timezone - typically wake up time."
        ),
        "windDownEndMinute": Schema.Parameter(
          type: .optionalInteger,
          description: "Recommended bedtime wind down end minute (0-59)."
        ),
        "phaseTip": Schema.Parameter(
          type: .optionalString,
          description: "One actionable tip relevant to the user's current menstrual cycle phase. Only include if the user has menstrual cycle data available."
        ),
        "periodForecast": Schema.Parameter(
          type: .optionalString,
          description: "Natural language forecast about the user's upcoming period. Only include when the predicted period is within approximately 7 days."
        )
      ]
    )
  )
}
