//
//  MorningHealthReport+DTO.swift
//  Bloom
//
//  Created by Assistant on 2025-07-24.
//

import Foundation
import SwiftData

public struct MorningHealthReportDTO: Sendable, Equatable, Identifiable {
  public let persistentID: PersistentIdentifier
  public let id: String
  public let day: Date
  public let sleepFeedback: String?
  public let readinessScore: Int
  public let readinessSummary: String?
  public let todaysFocus: String?
  public let insights: [MorningHealthInsightDTO]
}

public extension MorningHealthReport {
  func asDTO() -> MorningHealthReportDTO {
    MorningHealthReportDTO(
      persistentID: persistentModelID,
      id: id,
      day: day,
      sleepFeedback: sleepFeedback,
      readinessScore: readinessScore,
      readinessSummary: readinessSummary,
      todaysFocus: todaysFocus,
      insights: insights?.compactMap { $0.asDTO() } ?? []
    )
  }
}
