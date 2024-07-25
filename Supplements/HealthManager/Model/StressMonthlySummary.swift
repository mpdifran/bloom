//
//  StressMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-25.
//

import SwiftUI

private extension Double {
    static let hrvVariance: Double = 8
    static let rhrUpperThreadDiff: Double = 10
}

extension StressMonthlySummary {
    enum Level {
        case low
        case moderate
        case high
        case severe

        var name: String {
            switch self {
            case .low: "Low"
            case .moderate: "Moderate"
            case .high: "High"
            case .severe: "Severe"
            }
        }

        var color: Color {
            switch self {
            case .low: .coreSleep
            case .moderate: .green
            case .high: .yellow
            case .severe: .pink
            }
        }
    }
}

struct StressMonthlySummary: Equatable {
    let avgHeartRateVariability: Double
    let varHeartRateVariability: Double
    let restingHeartRate: Double
    let sleepScore: Double?
    let lastMonthAvgHeartRateVariability: Double
    let lastMonthVarHeartRateVariability: Double
    let lastMonthRestingHeartRate: Double
    let lastMonthSleepScore: Double?
}

extension StressMonthlySummary {

    var score: Double {
        let hrvScore = varHeartRateVariability.scaledPercent(lower: 0, upper: 500)

        let (min, max) = HealthManager.shared.goalRestingHeartRateForUser()
        let rhrScore = restingHeartRate.scaledPercent(lower: max, upper: min)

        if let sleepScore {
            return [hrvScore, rhrScore, sleepScore / 10].average(keyPath: \.self)
        } else {
            return [hrvScore, rhrScore].average(keyPath: \.self)
        }
    }

    var lastMonthScore: Double {
        let hrvScore = lastMonthVarHeartRateVariability.scaledPercent(lower: 0, upper: 100)

        let (min, max) = HealthManager.shared.goalRestingHeartRateForUser()
        let rhrScore = lastMonthRestingHeartRate.scaledPercent(lower: max, upper: min)

        if let sleepScore = lastMonthSleepScore {
            return [hrvScore, rhrScore, sleepScore / 10].average(keyPath: \.self)
        } else {
            return [hrvScore, rhrScore].average(keyPath: \.self)
        }
    }

    var trend: MonthlyVitalCardCell.Trend {
        lastMonthScore > score  ? .increasing : .decreasing
    }

    var subtitle: String {
        let hrv = "HRV: \(String(format: "%.0f", avgHeartRateVariability)) ms"
        let rhr = "RHR: \(String(format: "%.0f", restingHeartRate)) bpm"
        return [hrv, rhr].joined(separator: "\n")
    }

    var level: Level {
        if score < 0.4 {
            return .severe
        } else if score < 0.7 {
            return .high
        } else if score < 0.9 {
            return .moderate
        } else {
            return .low
        }
    }
}

