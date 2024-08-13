//
//  SleepVitalsMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SwiftUI

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
            case .poor: .pink
            case .low: .yellow
            case .good: .green
            case .great: .coreSleep
            }
        }
    }
}

struct SleepVitalsMonthlySummary: Equatable, Codable {
    let averageREMSleepPercent: Double
    let averageCoreSleepPercent: Double
    let averageDeepSleepPercent: Double
    let averageAwakeSleepPercent: Double
    let averageSleepLength: Double
    let averageSleepScore: Double
    let lastMonthAverageSleepScore: Double
}

extension SleepVitalsMonthlySummary {

    var score: Double {
        averageSleepScore.scaledPercent(lower: 4, upper: 8)
    }

    var trend: VitalModel.Trend {
        averageSleepScore > lastMonthAverageSleepScore ? .increasing : .decreasing
    }

    var quality: SleepQuality {
        if averageSleepScore < 4 {
            .poor
        } else if averageSleepScore < 7 {
            .low
        } else if averageSleepScore < 9 {
            .good
        } else {
            .great
        }
    }

    var subtitleText: String {
        let formattedDuration = DateFormatter.timeIntervalHourMinuteShort.string(from: .init(minute: Int(averageSleepLength)))
        let duration = formattedDuration.map { "Avg: \($0)" }
        let rem = "REM: \(String(format: "%.0f", averageREMSleepPercent * 100))%"
        let deep = "Deep: \(String(format: "%.0f", averageDeepSleepPercent * 100))%"
        return [duration, rem, deep].compactMap({ $0 }).joined(separator: "\n")
    }
}
