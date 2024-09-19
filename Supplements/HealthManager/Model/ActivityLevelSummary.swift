//
//  ActivityLevelSummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SwiftUI
import DataContainer

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
        case .sedentary: .vitalWarning
        case .light, .moderate: .vitalGood
        case .high, .intense: .vitalGreat
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

struct ActivityLevelSummary: Hashable, Codable, Sendable {
    let details: Details
    let lastMonthDetails: Details
}

extension ActivityLevelSummary {

    var trend: VitalModel.Trend {
        guard let thisMonth = details.activityRatio, let lastMonth = details.activityRatio else { return .noTrend }

        return thisMonth > lastMonth ? .increasing : .decreasing
    }

    var subtitle: String {
        let basal = details.averageBasalEnergyBurned
        let active = details.averageActiveEnergyBurned

        guard basal > 1 else { return "No Data" }

        return "\(String(format: "%.0f", basal)) Cal Basal\n\(String(format: "%.0f", active)) Cal Active"
    }
}

extension ActivityLevelSummary {
    struct Details: Hashable, Codable, Sendable {
        let averageBasalEnergyBurned: Double
        let averageActiveEnergyBurned: Double
        let energyRatioSamples: [DateValueSample]
    }
}

extension ActivityLevelSummary.Details {

    var activityRatio: Double? {
        guard averageBasalEnergyBurned > 1 else {
            return nil
        }
        return (averageActiveEnergyBurned + averageBasalEnergyBurned) / averageBasalEnergyBurned
    }

    var score: Double {
        guard let activityRatio else { return 1 }

        return activityRatio.scaledPercent(lower: 1, upper: 1.2)
    }

    var activityLevel: ActivityLevelSummary.ActivityLevel? {
        guard let ratio = activityRatio else { return nil }

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
                if level.range.contains(sample.value) {
                    ratioDistribution[level, default: 0] += 1
                }
            }
        }

        return ratioDistribution
    }

    func dayOfWeekActivityLevelRatioDistribution() -> [Int : Double] {
        var collection = [Int : [Double]]()
        for sample in energyRatioSamples {
            let dayOfWeek = Calendar.current.component(.weekday, from: sample.date)
            collection[dayOfWeek, default: []].append(sample.value)
        }

        var result = [Int : Double]()
        for key in collection.keys {
            result[key] = collection[key, default: []].average(keyPath: \.self)
        }

        return result
    }
}
