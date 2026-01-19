//
//  ResponseSchema+MonitorInsight.swift
//  Bloom-Backend
//
//  Created by Claude on 2026-01-19.
//

import Foundation
import BloomModel
@preconcurrency import OpenAIKit

extension ResponseSchema {

  static let monitorInsight = ResponseSchema(
    name: "monitorInsight",
    schema: Schema.Object(
      properties: [
        "insight": Schema.Parameter(
          type: .string,
          description: "1-2 sentences about what the monitor data shows for this user, using plain non-medical language. Reference 'your usual' patterns rather than population norms."
        ),
        "suggestion": Schema.Parameter(
          type: .optionalString,
          description: "Optional single actionable suggestion if one is clearly warranted. Omit if not applicable."
        )
      ]
    )
  )
}
