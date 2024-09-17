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

struct SleepVitalsMonthlySummary: Hashable, Codable {
    let details: Details
    let lastMonthDetails: Details
}

extension SleepVitalsMonthlySummary {

    var score: Double {
        details.score ?? 1
    }

    var trend: VitalModel.Trend {
        guard let thisMonth = details.score, let lastMonth = lastMonthDetails.score else { return .noTrend }

        return thisMonth > lastMonth ? .increasing : .decreasing
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
    struct Details: Hashable, Codable {
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

        if averageSleepScore < 4 {
            return .poor
        } else if averageSleepScore < 7 {
            return .low
        } else if averageSleepScore < 9 {
            return .good
        } else {
            return .great
        }
    }
}
