//
//  GoalGridMonthModel.swift
//  BloomUI
//
//  Created by Claude Code on 2025-10-30.
//

import SwiftUI

public struct GoalGridMonthModel: Hashable, Sendable, Codable {
  public let months: [Month]

  public init(months: [Month]) {
    self.months = months
  }

  public init() {
    var months = [Month]()
    for index in 0 ..< 12 {
      months.insert(Month(id: index, isComplete: nil), at: 0)
    }
    self.months = months
  }
}

public extension GoalGridMonthModel {
  struct Month: Identifiable, Hashable, Sendable, Codable {
    public let id: Int
    public let isComplete: Bool?
    public let isCurrentMonth: Bool
    public let monthLabel: String

    public init(
      id: Int,
      isComplete: Bool?,
      isCurrentMonth: Bool = false,
      monthLabel: String = ""
    ) {
      self.id = id
      self.isComplete = isComplete
      self.isCurrentMonth = isCurrentMonth
      self.monthLabel = monthLabel
    }
  }
}
