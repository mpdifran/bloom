//
//  EnergyBurnedSummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SwiftUI

extension EnergyBurnedSummary {
    enum ActivityLevel {
        case sedentary
        case light
        case moderate
        case high
        case intense
    }
}

extension EnergyBurnedSummary.ActivityLevel {

    var name: String {
        switch self {
        case .sedentary: "Sedentary"
        case .light: "Light"
        case .moderate: "Moderate"
        case .high: "High"
        case .intense: "Intense"
        }
    }

    var color: Color {
        switch self {
        case .sedentary: .yellow
        case .light, .moderate: .green
        case .high: .coreSleep
        case .intense: .coreSleep
        }
    }
}

struct EnergyBurnedSummary: Equatable {
    let averageBasalEnergyBurned: Double
    let averageActiveEnergyBurned: Double
    let lastMonthAverageBasalEnergyBurned: Double
    let lastMonthAverageActiveEnergyBurned: Double
}

extension EnergyBurnedSummary {

    var score: Double {
        guard let activityRatio else { return 1 }

        return activityRatio.scaledPercent(lower: 1, upper: 1.2)
    }

    var activityRatio: Double? {
        guard averageBasalEnergyBurned > 1 else {
            return nil
        }
        return (averageActiveEnergyBurned + averageBasalEnergyBurned) / averageBasalEnergyBurned
    }

    var lastMonthActivityRatio: Double? {
        guard lastMonthAverageBasalEnergyBurned > 1 else {
            return nil
        }
        return (lastMonthAverageActiveEnergyBurned + lastMonthAverageBasalEnergyBurned) / lastMonthAverageBasalEnergyBurned
    }

    var trend: VitalModel.Trend {
        guard let activityRatio, let lastMonthActivityRatio else { return .noTrend }

        return activityRatio > lastMonthActivityRatio ? .increasing : .decreasing
    }

    var subtitle: String {
        "\(String(format: "%.0f", averageBasalEnergyBurned)) Cal Basal\n\(String(format: "%.0f", averageActiveEnergyBurned)) Cal Active"
    }

    var activityLevel: ActivityLevel {
        let ratio = activityRatio ?? 0
        if ratio < 1.2 {
            return .sedentary
        } else if ratio < 1.375 {
            return .light
        } else if ratio < 1.55 {
            return .moderate
        } else if ratio < 1.725 {
            return .high
        } else {
            return .intense
        }
    }
}
