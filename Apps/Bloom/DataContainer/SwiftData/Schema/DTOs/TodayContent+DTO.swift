//
//  TodayContent+DTO.swift
//  DataContainer
//
//  Created by Assistant on 2025-08-29.
//

import Foundation
import SwiftData

@available(*, deprecated, message: "TodayContent+DTO is deprecated. Use standalone TodayContentDTO instead.")
public extension SchemaV25.TodayContent {
  func asDTO() -> TodayContentDTO {
    TodayContentDTO(
      day: day,
      timestamp: timestamp,
      summary: summary ?? "",
      budState: budState ?? "",
      todaysAdvice: todaysAdvice ?? "",
      sleepDetails: sleepDetails,
      tonightsSleepRecommendations: tonightsSleepRecommendations ?? "",
      insights: (insights ?? []).compactMap { $0.asDTO() }
    )
  }
}

@available(*, deprecated, message: "TodayInsight+DTO is deprecated. Use standalone TodayInsightDTO instead.")
public extension SchemaV25.TodayInsight {
  func asDTO() -> TodayInsightDTO {
    TodayInsightDTO(
      title: title ?? "",
      body: body ?? "",
      priority: priority
    )
  }
}