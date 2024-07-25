//
//  CardioFitnessMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SwiftUI

extension CardioFitnessMonthlySummary {
    enum FitnessLevel {
        case unknown
        case low
        case belowAverage
        case aboveAverage
        case high

        var name: String {
            switch self {
            case .unknown: "Unknown"
            case .low: "Low"
            case .belowAverage: "Below Average"
            case .aboveAverage: "Above Average"
            case .high: "High"
            }
        }

        var color: Color {
            switch self {
            case .unknown: .gray
            case .low: .pink
            case .belowAverage: .yellow
            case .aboveAverage: .green
            case .high: .coreSleep
            }
        }
    }
}

struct CardioFitnessMonthlySummary: Equatable {
    let averageVO2Max: Double?
    let lastMonthAverageVO2Max: Double?
}

extension CardioFitnessMonthlySummary {

    var trend: MonthlyVitalCardCell.Trend {
        guard let averageVO2Max, let lastMonthAverageVO2Max else {
            return .noTrend
        }
        return averageVO2Max > lastMonthAverageVO2Max ? .increasing : .decreasing
    }

    var subtitle: String {
        guard let averageVO2Max else { return "No Data" }

        return "\(String(format: "%.1f", averageVO2Max)) VO₂ Max"
    }

    var level: FitnessLevel {
        guard let goal = HealthManager.shared.goalVO2MaxForUser(), let averageVO2Max else {
            return .unknown
        }

        if averageVO2Max > goal.0 {
            return .high
        } else if averageVO2Max > goal.1 {
            return .aboveAverage
        } else if averageVO2Max > goal.2 {
            return .belowAverage
        } else {
            return .low
        }
    }
}
