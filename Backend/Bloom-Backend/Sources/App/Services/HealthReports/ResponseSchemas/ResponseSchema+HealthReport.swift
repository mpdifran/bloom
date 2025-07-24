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
}
