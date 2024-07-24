//
//  EnergyBurnedSummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import Foundation

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
}

struct EnergyBurnedSummary {
    let averageBasalEnergyBurned: Double
    let averageActiveEnergyBurned: Double
    let lastMonthAverageBasalEnergyBurned: Double
    let lastMonthAverageActiveEnergyBurned: Double
}

extension EnergyBurnedSummary {

    var activityRatio: Double {
        guard averageBasalEnergyBurned > 1 else {
            return 0
        }
        return (averageActiveEnergyBurned + averageBasalEnergyBurned) / averageBasalEnergyBurned
    }

    var lastMonthActivityRatio: Double {
        guard lastMonthAverageBasalEnergyBurned > 1 else {
            return 0
        }
        return (lastMonthAverageActiveEnergyBurned + lastMonthAverageBasalEnergyBurned) / lastMonthAverageBasalEnergyBurned
    }

    var isIncreasing: Bool {
        lastMonthActivityRatio > activityRatio
    }

    var activityLevel: ActivityLevel {
        switch activityRatio {
        case ...1.2:
            .sedentary
        case 1.2...1.375:
            .light
        case 1.375...1.55:
            .moderate
        case 1.55...1.725:
            .high
        case 1.725...:
            .intense
        default:
            .sedentary
        }
    }
}
