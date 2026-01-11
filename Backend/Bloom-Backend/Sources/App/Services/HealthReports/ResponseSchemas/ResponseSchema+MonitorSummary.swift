//
//  ResponseSchema+MonitorSummary.swift
//  Bloom-Backend
//
//  Created by Claude on 2026-01-10.
//

import Foundation
import BloomModel
@preconcurrency import OpenAIKit

extension ResponseSchema {

  static let monitorSummary = ResponseSchema(
    name: "monitorSummary",
    schema: Schema.Object(
      properties: [
        "summary": Schema.Parameter(
          type: .string,
          description: "A 1-2 sentence overview of what the monitor data shows, using plain non-medical language. Reference 'your usual' patterns rather than population norms."
        ),
        "notificationBody": Schema.Parameter(
          type: .string,
          description: "A concise 1-sentence version optimized for push notification display. Should be punchy and actionable, not alarming."
        ),
        "recommendations": Schema.Parameter(
          description: "2-4 specific, actionable recommendations the user can act on today. Focus on practical advice like rest, hydration, sleep timing, and activity adjustments.",
          arrayOf: Schema.Item.parameter(
            Schema.Parameter(
              type: .string,
              description: "A single actionable recommendation"
            )
          )
        ),
        "contextNote": Schema.Parameter(
          type: .optionalString,
          description: "Optional additional context explaining patterns or providing reassurance. Only include if it adds value to the summary."
        )
      ]
    )
  )
}
