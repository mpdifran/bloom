//
//  DateCollatedWorkoutHeartRateReport.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-03.
//

import Foundation

public struct DateCollatedWorkoutHeartRateReport: Identifiable, Hashable, Sendable {
  public var id: Int { hashValue }

  public let date: Date
  public let reports: [WorkoutHeartRateReport]

  public init(date: Date, reports: [WorkoutHeartRateReport]) {
    self.date = date
    self.reports = reports
  }
}
