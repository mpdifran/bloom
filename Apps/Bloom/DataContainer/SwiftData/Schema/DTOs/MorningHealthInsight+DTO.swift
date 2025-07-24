//
//  MorningHealthInsight+DTO.swift
//  Bloom
//
//  Created by Assistant on 2025-07-24.
//

import Foundation
import SwiftData

public struct MorningHealthInsightDTO: Sendable, Equatable, Identifiable {
  public let persistentID: PersistentIdentifier
  public let id: String
  public let title: String?
  public let body: String?
  public let emoji: String?
  public let relevanceScore: Double
}

public extension MorningHealthInsight {
  func asDTO() -> MorningHealthInsightDTO {
    MorningHealthInsightDTO(
      persistentID: persistentModelID,
      id: id,
      title: title,
      body: body,
      emoji: emoji,
      relevanceScore: relevanceScore
    )
  }
}