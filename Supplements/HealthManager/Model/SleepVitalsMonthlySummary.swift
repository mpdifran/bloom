//
//  SleepVitalsMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SwiftUI
import DataContainer

extension SleepVitalsMonthlySummary {
    enum SleepQuality: CaseIterable {
        case poor
        case low
        case good
        case great

        init(sleepScore: Double) {
            if sleepScore < 4 {
                self = .poor
            } else if sleepScore < 7 {
                self = .low
            } else if sleepScore < 9 {
                self = .good
            } else {
                self = .great
            }
        }

        var name: String {
            switch self {
            case .poor: "Poor"
            case .low: "Low"
            case .good: "Good"
            case .great: "Great"
            }
        }

        var color: Color {
            switch self {
            case .poor: .vitalSevere
            case .low: .vitalWarning
            case .good: .vitalGood
            case .great: .vitalGreat
            }
        }
    }
}

struct SleepVitalsMonthlySummary: Hashable, Codable, Sendable {
    let details: Details
    let lastMonthDetails: Details
}

extension SleepVitalsMonthlySummary {

    var score: Double {
        details.score ?? 1
    }

    var barLevel: VitalModel.BarLevel? {
        guard
            let averageSleepScore = details.averageSleepScore,
            let level = details.quality
        else { return nil }

        switch level {
        case .poor:
            return VitalModel.BarLevel(
                level: .low,
                proportion: averageSleepScore.scaledPercent(lower: 0, upper: 4)
            )
        case .low:
            return VitalModel.BarLevel(
                level: .medium,
                proportion: averageSleepScore.scaledPercent(lower: 4, upper: 7)
            )
        case .good:
            return VitalModel.BarLevel(
                level: .high,
                proportion: averageSleepScore.scaledPercent(lower: 7, upper: 9)
            )
        case .great:
            return VitalModel.BarLevel(
                level: .optimal,
                proportion: averageSleepScore.scaledPercent(lower: 9, upper: 10)
            )
        }
    }

    var subtitleText: String? {
        var entries = [String?]()

        if
            let averageSleepLength = details.averageSleepLength,
            let formattedDuration = DateFormatter.timeIntervalHourMinuteShort.string(from: .init(minute: Int(averageSleepLength)))
        {
            entries.append("Avg: \(formattedDuration)")
        }

        if let averageREMSleepPercent = details.averageREMSleepPercent {
            entries.append("REM: \(String(format: "%.0f", averageREMSleepPercent * 100))%")
        }
        if let averageDeepSleepPercent = details.averageDeepSleepPercent {
            entries.append("Deep: \(String(format: "%.0f", averageDeepSleepPercent * 100))%")
        }

        let nonNilEntries = entries.compactMap({ $0 })

        guard nonNilEntries.isNotEmpty else { return nil }

        return nonNilEntries.joined(separator: "\n")
    }
}

extension SleepVitalsMonthlySummary {
    struct Details: Hashable, Codable, Sendable {
        let averageREMSleepPercent: Double?
        let averageCoreSleepPercent: Double?
        let averageDeepSleepPercent: Double?
        let averageAwakeSleepPercent: Double?
        let averageSleepLength: Double?
        let averageSleepScore: Double?
    }
}

extension SleepVitalsMonthlySummary.Details {

    var score: Double? {
        averageSleepScore?.scaledPercent(lower: 4, upper: 8)
    }

    var quality: SleepVitalsMonthlySummary.SleepQuality? {
        guard let averageSleepScore else { return nil }

        return SleepVitalsMonthlySummary.SleepQuality(sleepScore: averageSleepScore)
    }
}
