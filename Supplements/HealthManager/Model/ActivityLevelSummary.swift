//
//  ActivityLevelSummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SwiftUI

extension ActivityLevelSummary {
    enum ActivityLevel: CaseIterable, Identifiable {
        var id: Self { self }

        case sedentary
        case light
        case moderate
        case high
        case intense

        init(_ ratio: Double) {
            if ratio < 1.2 {
                self = .sedentary
            } else if ratio < 1.375 {
                self = .light
            } else if ratio < 1.55 {
                self = .moderate
            } else if ratio < 1.725 {
                self = .high
            } else {
                self = .intense
            }
        }
    }
}

extension ActivityLevelSummary.ActivityLevel {

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

    var barColor: Color {
        switch self {
        case .sedentary:
                .activityLevelSedentary
        case .light:
                .activityLevelLight
        case .moderate:
                .activityLevelModerate
        case .high:
                .activityLevelHigh
        case .intense:
                .activityLevelIntense
        }
    }

    var range: ClosedRange<Double> {
        switch self {
        case .sedentary:
            1...1.2
        case .light:
            1.2...1.375
        case .moderate:
            1.375...1.55
        case .high:
            1.55...1.725
        case .intense:
            1.725...2.5
        }
    }
}

struct ActivityLevelSummary: Equatable, Codable {
    let averageBasalEnergyBurned: Double
    let averageActiveEnergyBurned: Double
    let energyRatioSamples: [DateQuantitySample]
    let lastMonthAverageBasalEnergyBurned: Double
    let lastMonthAverageActiveEnergyBurned: Double
    let lastMonthEnergyRatioSamples: [DateQuantitySample]
}

extension ActivityLevelSummary {

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

    var activityLevelRatioDistribution: [ActivityLevelSummary.ActivityLevel : Int] {
        var ratioDistribution = [ActivityLevelSummary.ActivityLevel : Int]()
        for sample in energyRatioSamples {
            for level in ActivityLevelSummary.ActivityLevel.allCases {
                if level.range.contains(sample.quantity) {
                    ratioDistribution[level, default: 0] += 1
                }
            }
        }

        return ratioDistribution
    }
}
