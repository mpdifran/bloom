//
//  MenstrualCycle.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-12.
//

import Foundation
@preconcurrency import HealthKit

public extension MenstrualCycle {
  enum MenstrualFlow: Int {
    case unspecified = 1
    case light = 2
    case medium = 3
    case heavy = 4
    case none = 5
  }
}

public struct MenstrualCycle: Hashable, Identifiable, Sendable {
  public var id: Int { hashValue }

  public let startDate: Date
  public let samples: [HKCategorySample]

  public init(startDate: Date, samples: [HKCategorySample]) {
    self.startDate = startDate
    self.samples = samples
  }
}

public extension MenstrualCycle {

  var endDate: Date? {
    samples.max(keyPath: \.endDate)
  }

  var menstruationDurationDays: Int? {
    guard
      let start = samples.min(keyPath: \.startDate),
      let end = samples.max(keyPath: \.endDate)
    else { return nil }

    if let days = Calendar.current.dateComponents([.day], from: start, to: end).day {
      return days + 1
    }
    return nil
  }
}
