//
//  HeartHealthMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SwiftUI
import DataContainer
import HealthKit

extension Double {
    static let maxHeartRateRecovery: Double = 18
    static let minHeartRateRecovery: Double = 10
}

extension HeartHealthMonthlySummary {
    enum HeartHealthLevel {
        case atRisk
        case moderate // Could be fair
        case healthy
        case optimal

        var name: String {
            switch self {
            case .atRisk: "At Risk"
            case .moderate: "Moderate"
            case .healthy: "Healthy"
            case .optimal: "Optimal"
            }
        }

        var color: Color {
            switch self {
            case .atRisk: .vitalSevere
            case .moderate: .vitalWarning
            case .healthy: .vitalGood
            case .optimal: .vitalGreat
            }
        }
    }

    enum CardioFitnessLevel {
        case low
        case belowAverage
        case aboveAverage
        case high

        var name: String {
            switch self {
            case .low: "Low"
            case .belowAverage: "Below Average"
            case .aboveAverage: "Above Average"
            case .high: "High"
            }
        }

        var color: Color {
            switch self {
            case .low: .vitalSevere
            case .belowAverage: .vitalWarning
            case .aboveAverage: .vitalGood
            case .high: .vitalGreat
            }
        }

        var summary: String {
            switch self {
            case .low:
                "This level indicates poor cardiovascular fitness and is associated with a higher risk of cardiovascular diseases and other health issues."
            case .belowAverage:
                "Individuals in this category have cardiovascular fitness below the median but are not in the lowest fitness category."
            case .aboveAverage:
                "This level represents better-than-average cardiovascular fitness and suggests a lower risk of cardiovascular diseases."
            case .high:
                "This top level is characterized by superior cardiovascular fitness, often indicating excellent overall health and a lower risk of heart-related conditions."
            }
        }
    }
}

// TODO: Incorporate resting heart rate
struct HeartHealthMonthlySummary: Hashable, Sendable {
    let details: Details
    let lastMonthDetails: Details
}

extension HeartHealthMonthlySummary {
    struct Details: Hashable, Sendable {
        let averageVO2Max: HKQuantity?
        let averageHeartRateRecovery: HKQuantity?
        let averageRestingHeartRate: HKQuantity?
    }
}

extension HeartHealthMonthlySummary.Details {

    var score: Double? {
        let scores = [
            vo2MaxScore,
            heartRateRecoveryScore,
            restingHeartRateScore
        ].unwrap()

        if scores.isEmpty { return nil }

        return scores.average(keyPath: \.self)
    }

    var barLevel: VitalModel.BarLevel? {
        guard let level, let score else { return nil }

        switch level {
        case .atRisk:
            return VitalModel.BarLevel(
                level: .low,
                proportion: score.scaledPercent(lower: 0, upper: 0.4)
            )
        case .moderate:
            return VitalModel.BarLevel(
                level: .medium,
                proportion: score.scaledPercent(lower: 0.4, upper: 0.7)
            )
        case .healthy:
            return VitalModel.BarLevel(
                level: .high,
                proportion: score.scaledPercent(lower: 0.7, upper: 0.95)
            )
        case .optimal:
            return VitalModel.BarLevel(
                level: .optimal,
                proportion: score.scaledPercent(lower: 0.95, upper: 1)
            )
        }
    }

    var level: HeartHealthMonthlySummary.HeartHealthLevel? {
        guard let score else { return nil }

        // TODO: Vet these scores
        if score > 0.95 {
            return .optimal
        } else if score > 0.7 {
            return .healthy
        } else if score > 0.4 {
            return .moderate
        } else {
            return .atRisk
        }
    }

    var cardioFitnessLevel: HeartHealthMonthlySummary.CardioFitnessLevel? {
        guard let goal = HealthManager.shared.goalVO2MaxForUser(), let averageVO2Max else { return nil }

        let vo2Max = averageVO2Max.doubleValue(for: .vo2Max())

        if vo2Max < goal.2 {
            return .low
        } else if vo2Max < goal.1 {
            return .belowAverage
        } else if vo2Max < goal.0 {
            return .aboveAverage
        } else {
            return .high
        }
    }

    var subtitle: String? {
        let vo2Max = averageVO2Max.map { "VO₂ Max: \($0.displayString(for: .vo2Max()))" }
        let rhr = averageRestingHeartRate.map { _ in "RHR: \(displayRestingHeartRate)" }
        let heartRateRecovery = averageHeartRateRecovery.map { _ in "HRR: \(displayHeartRateRecovery)" }

        let descriptions = [vo2Max, rhr, heartRateRecovery].unwrap()

        if descriptions.isEmpty {
            return nil
        }
        return descriptions.joined(separator: "\n")
    }

    var displayHeartRateRecovery: String {
        guard let averageHeartRateRecovery else { return "" }
        return "\(averageHeartRateRecovery.doubleValue(for: .bpm()).format()) bpm"
    }

    var displayRestingHeartRate: String {
        guard let averageRestingHeartRate else { return "" }
        return "\(averageRestingHeartRate.doubleValue(for: .bpm()).format()) bpm"
    }
}

private extension HeartHealthMonthlySummary.Details {

    var vo2MaxScore: Double? {
        if let goal = HealthManager.shared.goalVO2MaxForUser() {
            return averageVO2Max?.doubleValue(for: .vo2Max()).scaledPercent(lower: goal.2, upper: goal.1)
        }
        return nil
    }

    var heartRateRecoveryScore: Double? {
        averageHeartRateRecovery?.doubleValue(for: .bpm()).scaledPercent(
            lower: .minHeartRateRecovery,
            upper: .maxHeartRateRecovery
        )
    }

    var restingHeartRateScore: Double? {
        let (min, max) = HealthManager.shared.goalRestingHeartRateForUser()

        return averageRestingHeartRate?.doubleValue(for: .bpm()).scaledPercent(lower: max + 10, upper: max)
    }
}
