//
//  GoalGridWeekModel.swift
//  BloomUI
//
//  Created by Claude Code on 2025-10-30.
//

import SwiftUI

public struct GoalGridWeekModel: Hashable, Sendable, Codable {
  public let weeks: [Week]

  public init(weeks: [Week]) {
    self.weeks = weeks
  }

  public init() {
    var weeks = [Week]()
    for index in 0 ..< 20 {
      weeks.insert(Week(id: index, isComplete: nil), at: 0)
    }
    self.weeks = weeks
  }
}

public extension GoalGridWeekModel {
  struct Week: Identifiable, Hashable, Sendable, Codable {
    public let id: Int
    public let isComplete: Bool?
    public let isCurrentWeek: Bool
    public let referenceDate: Date
    public let monthLabel: String?

    public init(
      id: Int,
      isComplete: Bool?,
      isCurrentWeek: Bool = false,
      referenceDate: Date = .now,
      monthLabel: String? = nil
    ) {
      self.id = id
      self.isComplete = isComplete
      self.isCurrentWeek = isCurrentWeek
      self.referenceDate = referenceDate
      self.monthLabel = monthLabel
    }
  }
}
