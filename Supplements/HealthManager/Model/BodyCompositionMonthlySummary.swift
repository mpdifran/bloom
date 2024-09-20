//
//  BodyCompositionMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SwiftUI
import HealthKit
import DataContainer

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

struct BodyCompositionMonthlySummary: Hashable, Sendable {
    let details: Details
    let lastMonthDetails: Details
}

extension BodyCompositionMonthlySummary {

    var score: Double {
        details.score ?? 1
    }

    var trend: VitalModel.Trend {
        guard let thisMonth = details.score, let lastMonth = lastMonthDetails.score else {
            return .noTrend
        }
        return thisMonth > lastMonth ? .increasing : .decreasing
    }

    var subtitle: String? {
        var entries = [String]()

        if let bodyWeight = details.averageBodyMass {
            entries.append("Avg Weight: \(bodyWeight.displayString(for: .pound(), formatter: .oneDecimalPlace))")
        }
        if let bodyFatPercentage = details.bodyFatPercentage?.doubleValue(for: .percent()) {
            let percent = bodyFatPercentage * 100
            entries.append("Fat: \(percent.format())%")
        }

        let compactEntries = entries.compactMap({ $0 })

        guard compactEntries.isNotEmpty else { return nil }

        return compactEntries.joined(separator: "\n")
    }

    var bodyMassTrendDescription: String? {
        guard
            let thisMonth = details.averageBodyMass?.doubleValue(for: .pound()),
            let lastMonth = lastMonthDetails.averageBodyMass?.doubleValue(for: .pound())
        else { return nil }

        let difference = abs(thisMonth - lastMonth)

        if difference < 1 {
            return "Your average body weight has held steady over this month compared to last month."
        }

        if thisMonth > lastMonth {
            let formattedPercent = ((thisMonth - lastMonth) / lastMonth * 100).format(using: .oneDecimalPlace)
            return "Your average body weight has increased \(formattedPercent)% this month."
        } else {
            let formattedPercent = ((lastMonth - thisMonth) / lastMonth * 100).format(using: .oneDecimalPlace)
            return "Your average body weight has decreased \(formattedPercent)% this month."
        }
    }
}

extension BodyCompositionMonthlySummary {
    struct Details: Hashable, Sendable {
        let bodyFatPercentage: HKQuantity?
        let averageBodyMass: HKQuantity?
    }
}

extension BodyCompositionMonthlySummary.Details {

    var score: Double? {
        guard
            let goal = HealthManager.shared.goalBodyFatPercentage(),
            let bodyFatPercentage
        else { return nil }

        return bodyFatPercentage.doubleValue(for: .percent()).scaledPercent(lower: goal.4, upper: goal.3)
    }

    var range: BodyCompositionMonthlySummary.PercentageRange? {
        guard
            let goal = HealthManager.shared.goalBodyFatPercentage(),
            let bodyFatPercentage
        else {
            if averageBodyMass == nil {
                return nil
            }
            return .unknown
        }

        let percent = bodyFatPercentage.doubleValue(for: .percent())

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
