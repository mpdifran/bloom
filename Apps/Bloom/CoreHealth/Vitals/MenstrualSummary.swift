//
//  MenstrualSummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-12.
//

import SwiftUI

private extension Int {
  static let defaultMinMenstruationDays = 3

  /// Amount of days difference a typical cycle could be from the average.
  static let standardDeviationCycleDays = 5

  static let typicalCycleDuration = 28
}

public struct MenstrualSummary: Hashable, Sendable {
  public let menstrualCycles: [MenstrualCycle]

  public init(menstrualCycles: [MenstrualCycle]) {
    self.menstrualCycles = menstrualCycles
  }
}

public extension MenstrualSummary {

  var hasNoData: Bool {
    menstrualCycles.isEmpty
  }

  var subtitle: String? {
    var entries = [String]()

    if let averageCycleDuration {
      entries.append(String(
        localized: "\(averageCycleDuration) Day Cycle",
        bundle: Bundle.coreHealth,
        comment: "Menstrual subtitle line. The placeholder is the average cycle length in days."
      ))
    }

    if isMenstruating {
      entries.append(String(
        localized: "Menstruating",
        bundle: Bundle.coreHealth,
        comment: "Menstrual subtitle line shown while the user is on their period."
      ))
    } else {
      if let date = nextPredictedPeriodDate {
        let dateString = DateFormatter.monthAndDay.string(from: date)
        entries.append(String(
          localized: "Next Period: \(dateString)",
          bundle: Bundle.coreHealth,
          comment: "Menstrual subtitle line. The placeholder is a formatted month and day."
        ))
      }
    }

    guard entries.isNotEmpty else { return nil }

    return entries.joined(separator: "\n")
  }

  var phaseName: String? {
    if let phase = currentPhase() {
      return phase.name
    } else if menstrualCycles.isNotEmpty {
      return String(localized: "Calculating Cycle", bundle: Bundle.coreHealth, comment: "Placeholder phase name shown while the cycle is still being calculated")
    }
    return nil
  }

  var color: Color? {
    currentPhase()?.color
  }
}

public extension MenstrualSummary {

  var averageMenstruationDays: Int? {
    let doubleValue = menstrualCycles
      .compactMap({ $0.menstruationDurationDays.map { Double($0) } })
      .average(keyPath: \.self)
    return Int(doubleValue)
  }

  /// In days
  var averageCycleDuration: Int? {
    var previousCycle: MenstrualCycle?
    var days = [Double]()

    for current in menstrualCycles {
      if let previous = previousCycle {
        if let dayCount = Calendar.current.dateComponents([.day], from: previous.startDate, to: current.startDate).day {
          days.append(Double(dayCount))
        }
        previousCycle = current
      } else {
        previousCycle = current
      }
    }

    guard days.isNotEmpty else { return nil }

    return Int(days.average(keyPath: \.self))
  }

  var isMenstruating: Bool {
    guard
      let latestCycle = menstrualCycles.max(by: \.startDate),
      let days = Calendar.current.dateComponents([.day], from: latestCycle.startDate, to: .now).day
    else { return false }

    let daysSinceStart = days + 1

    if let averageMenstruationDays {
      if daysSinceStart < averageMenstruationDays {
        return true
      }
    } else {
      if daysSinceStart < .defaultMinMenstruationDays {
        return true
      }
    }
    return false
  }

  func currentPhase() -> MenstrualCyclePhase? {
    guard
      let latestCycle = menstrualCycles.max(by: \.startDate),
      let days = Calendar.current.dateComponents([.day], from: latestCycle.startDate, to: .now).day
    else { return nil }

    let cycleDuration = averageCycleDuration ?? .typicalCycleDuration
    let daysSinceStart = days + 1
    let ovulationDay = cycleDuration / 2
    let menstruationDuration = averageMenstruationDays ?? .defaultMinMenstruationDays

    // Menstrual phase: Days 1-5 (average menstruation duration)
    if daysSinceStart <= menstruationDuration {
      return .menstrual
    }

    // Follicular phase: After menstruation until ~2 days before ovulation
    if daysSinceStart < (ovulationDay - 1) {
      return .follicular
    }

    // Ovulation phase: ~3 day window centered on mid-cycle
    if daysSinceStart >= (ovulationDay - 1) && daysSinceStart <= (ovulationDay + 1) {
      return .ovulation
    }

    // Luteal phase: After ovulation until next predicted period
    if daysSinceStart < (cycleDuration + .standardDeviationCycleDays) {
      return .luteal
    }

    return .unknown
  }

  var mostRecentCycle: MenstrualCycle? {
    menstrualCycles.max(by: \.startDate)
  }

  var nextPredictedPeriodDate: Date? {
    guard
      let averageCycleDuration,
      let mostRecentCycle
    else { return nil }

    return Calendar.current.date(
      byAdding: .day,
      value: averageCycleDuration,
      to: mostRecentCycle.startDate
    )
  }

  var nextPredictedOvulationDate: Date? {
    guard
      let averageCycleDuration,
      let mostRecentCycle
    else { return nil }

    return Calendar.current.date(
      byAdding: .day,
      value: averageCycleDuration / 2,
      to: mostRecentCycle.startDate
    )
  }
}
