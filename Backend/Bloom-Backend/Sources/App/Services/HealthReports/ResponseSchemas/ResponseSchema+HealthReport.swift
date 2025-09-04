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
  
  static let morningHealthReport = ResponseSchema(
    name: "morningHealthReport",
    schema: Schema.Object(
      properties: [
        "sleepFeedback": Schema.Parameter(
          type: .string,
          description: "A summary of the user's sleep. Focus on potential issues, celebrate wins, and make sure advice is actionable."
        ),
        "notificationTitle": Schema.Parameter(
          type: .string,
          description: "The title for an iOS style notification that will be shown to the user when the report is ready. It should be something along the lines of \"Your morning report is ready!\" but more fun."
        ),
        "notificationBody": Schema.Parameter(
          type: .string,
          description: "This is the body of the iOS style notification. You can give a quick fun summary of what the user can find in the report."
        ),
        "insights": Schema.Parameter(
          description: "A list of insights you found in the user's health data, ordered from highest relevance to lowest relevance. Ignore any insights related to sleep, and use sleepFeedback instead.",
          arrayOf: Schema.Item.object(
            Schema.Object(
              properties: [
                "title": Schema.Parameter(
                  type: .string,
                  description: "A title for the insight. Do not use emojis here. Use the emoji property instead."
                ),
                "body": Schema.Parameter(
                  type: .string,
                  description: "The body for the insight itself."
                ),
                "emoji": Schema.Parameter(
                  type: .string,
                  description: "An emoji to represent the insight."
                ),
                "relevanceScore": Schema.Parameter(
                  type: .number,
                  description: "A number between 0 and 10 indicating how relevant and interesting this insight is to the user, with 10 being very relevant and interesting, and 0 being not at all relevant or interesting."
                )
              ]
            )
          )
        ),
        "readinessScore": Schema.Parameter(
          type: .number,
          description: "A readiness score from 1 to 10 indicating how ready the user is to tackle the day, where 1 is not ready at all and 10 is fully ready and energized. Consider factors like sleep quality, recovery metrics, stress levels, and overall health trends."
        ),
        "readinessSummary": Schema.Parameter(
          type: .string,
          description: "A brief 1-2 sentence summary explaining what factors contributed to the readiness score. Be specific about which health metrics influenced the score."
        ),
        "todaysFocus": Schema.Parameter(
          type: .string,
          description: "One specific, actionable health-related focus for today based on yesterday's data. This should be a single, clear recommendation that the user can act on throughout the day."
        )
      ]
    )
  )

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
        )
      ]
    )
  )
}
