//
//  GoalGridYearModel.swift
//  BloomUI
//
//  Created by Claude Code on 2025-10-30.
//

import SwiftUI

public struct GoalGridYearModel: Hashable, Sendable, Codable {
  public let years: [Year]

  public init(years: [Year]) {
    self.years = years
  }

  public init() {
    var years = [Year]()
    for index in 0 ..< 5 {
      years.insert(Year(id: index, isComplete: nil), at: 0)
    }
    self.years = years
  }
}

public extension GoalGridYearModel {
  struct Year: Identifiable, Hashable, Sendable, Codable {
    public let id: Int
    public let isComplete: Bool?
    public let isCurrentYear: Bool
    public let referenceDate: Date
    public let yearLabel: String

    public init(
      id: Int,
      isComplete: Bool?,
      isCurrentYear: Bool = false,
      referenceDate: Date = .now,
      yearLabel: String = ""
    ) {
      self.id = id
      self.isComplete = isComplete
      self.isCurrentYear = isCurrentYear
      self.referenceDate = referenceDate
      self.yearLabel = yearLabel
    }
  }
}
