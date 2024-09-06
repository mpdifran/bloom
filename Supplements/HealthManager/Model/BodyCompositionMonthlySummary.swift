//
//  BodyCompositionMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SwiftUI

extension BodyCompositionMonthlySummary {
    enum PercentageRange {
        case unknown
        case essentialFat
        case athlete
        case fit
        case healthy
        case high

        var name: String {
            switch self {
            case .unknown: "Unknown"
            case .essentialFat: "Essential Fat"
            case .athlete: "Athlete"
            case .fit: "Fit"
            case .healthy: "Healthy"
            case .high: "High"
            }
        }

        var color: Color {
            switch self {
            case .unknown: .gray
            case .athlete, .fit: .vitalGreat
            case .healthy: .vitalGood
            case .essentialFat: .vitalWarning
            case .high: .vitalSevere
            }
        }

        func rangeDescription(from goals: (Double, Double, Double, Double, Double)) -> String {
            guard let values = rangeValues(from: goals) else { return "" }

            return "\(values.lowerBound.formatted(.percent)) - \(values.upperBound.formatted(.percent))"
        }

        func rangeValues(from goals: (Double, Double, Double, Double, Double)) -> ClosedRange<Double>? {
            switch self {
            case .unknown:
                nil
            case .essentialFat:
                0...goals.0
            case .athlete:
                goals.0...goals.1
            case .fit:
                goals.1...goals.2
            case .healthy:
                goals.2...goals.3
            case .high:
                goals.3...1
            }
        }
    }
}

struct BodyCompositionMonthlySummary: Equatable, Codable {
    let bodyFatPercentage: Double?
    let lastMonthBodyFatPercentage: Double?
}

extension BodyCompositionMonthlySummary {

    var score: Double {
        guard
            let goal = HealthManager.shared.goalBodyFatPercentage(),
            let bodyFatPercentage
        else { return 1 }

        return bodyFatPercentage.scaledPercent(lower: goal.4, upper: goal.3)
    }

    var trend: VitalModel.Trend {
        guard let bodyFatPercentage, let lastMonthBodyFatPercentage else {
            return .noTrend
        }
        return bodyFatPercentage > lastMonthBodyFatPercentage ? .increasing : .decreasing
    }

    var subtitle: String {
        guard let bodyFatPercentage else { return "No Data" }

        let percent = bodyFatPercentage * 100
        return "Fat: \(percent.format(to: 0))%"
    }

    var range: PercentageRange {
        guard
            let goal = HealthManager.shared.goalBodyFatPercentage(),
            let bodyFatPercentage
        else { return .unknown }

        let percent = bodyFatPercentage

        if percent < goal.0 {
            return .essentialFat
        } else if percent < goal.1 {
            return .athlete
        } else if percent < goal.2 {
            return .fit
        } else if percent < goal.3 {
            return .healthy
        } else {
            return .high
        }
    }
}
