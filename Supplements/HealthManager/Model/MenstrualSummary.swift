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

struct MenstrualSummary: Hashable {
    let menstrualCycles: [MenstrualCycle]
}

extension MenstrualSummary {

    var subtitle: String? {
        var entries = [String]()

        if let averageCycleDuration {
            entries.append("\(averageCycleDuration) Day Cycle")
        }

        if isMenstruating {
            entries.append("Menstruating")
        } else {
            if let date = nextPredictedPeriodDate {
                let dateString = DateFormatter.monthAndDay.string(from: date)
                entries.append("Next Period: \(dateString)")
            }
        }

        guard entries.isNotEmpty else { return nil }

        return entries.joined(separator: "\n")
    }

    var phaseDescription: String? {
        if let phase = currentPhase() {
            return phase.name
        } else if menstrualCycles.isNotEmpty {
            return "Calculating Cycle"
        }
        return nil
    }

    var color: Color? {
        let phase = currentPhase()

        switch phase {
        case .follicular:
            return .mutedPurple
        case .luteal:
            return .mutedBlue
        case .ovulation:
            return .mutedIndigo
        default:
            return nil
        }
    }
}

extension MenstrualSummary {

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
        let ovulationDays = cycleDuration / 2

        if daysSinceStart < ovulationDays {
            return .follicular
        }

        // TODO: Rework this logic
        if daysSinceStart == ovulationDays {
            return .ovulation
        }

        if daysSinceStart < (cycleDuration + .standardDeviationCycleDays) {
            return .luteal
        }

        return .unknown
    }

    var nextPredictedPeriodDate: Date? {
        guard
            let averageCycleDuration,
            let mostRecentCycle = menstrualCycles.max(by: \.startDate)
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
            let mostRecentCycle = menstrualCycles.max(by: \.startDate)
        else { return nil }

        return Calendar.current.date(
            byAdding: .day,
            value: averageCycleDuration / 2,
            to: mostRecentCycle.startDate
        )
    }
}
