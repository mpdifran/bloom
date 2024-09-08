//
//  CardioFitnessMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SwiftUI

extension Double {
    static let maxHeartRateRecovery: Double = 18
    static let minHeartRateRecovery: Double = 10
}

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
            case .low: .vitalSevere
            case .belowAverage: .vitalWarning
            case .aboveAverage: .vitalGood
            case .high: .vitalGreat
            }
        }

        var summary: String {
            switch self {
            case .unknown:
                ""
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

struct CardioFitnessMonthlySummary: Equatable, Codable {
    let averageVO2Max: Double?
    let averageHeartRateRecovery: Double?
    let lastMonthAverageVO2Max: Double?
    let lastMonthAverageHeartRateRecovery: Double?
}

extension CardioFitnessMonthlySummary {

    var score: Double {
        if
            averageVO2Max == nil,
            averageHeartRateRecovery == nil
        {
            return 1
        }
        return internalScore
    }

    private var internalScore: Double {
        let vo2Max: Double?
        if let goal = HealthManager.shared.goalVO2MaxForUser() {
            vo2Max = averageVO2Max?.scaledPercent(lower: goal.2, upper: goal.1)
        } else {
            vo2Max = nil
        }

        let heartRate = averageHeartRateRecovery?.scaledPercent(
            lower: .minHeartRateRecovery,
            upper: .maxHeartRateRecovery
        )

        return [
            vo2Max,
            vo2Max, // Add it 3 times because it's more important
            vo2Max,
            heartRate
        ]
            .compactMap({ $0 })
            .average(keyPath: \.self)
    }

    private var lastMonthInternalScore: Double {
        let vo2Max: Double?
        if let goal = HealthManager.shared.goalVO2MaxForUser() {
            vo2Max = averageVO2Max?.scaledPercent(lower: goal.2, upper: goal.1)
        } else {
            vo2Max = nil
        }

        let heartRate = averageHeartRateRecovery?.scaledPercent(
            lower: .minHeartRateRecovery,
            upper: .maxHeartRateRecovery
        )

        return [
            vo2Max,
            vo2Max, // Add it 4 times because it's more important
            vo2Max,
            vo2Max,
            heartRate
        ]
            .compactMap({ $0 })
            .average(keyPath: \.self)
    }

    var trend: VitalModel.Trend {
        if
            averageVO2Max == nil,
            averageHeartRateRecovery == nil,
            lastMonthAverageVO2Max == nil,
            lastMonthAverageHeartRateRecovery == nil
        {
            return .noTrend
        }
        return internalScore > lastMonthInternalScore ? .increasing : .decreasing
    }

    var subtitle: String {
        let vo2Max = averageVO2Max.map { "VO₂ Max: \(String(format: "%.1f", $0)) mL/min·kg" }
        let heartRateRecovery = averageHeartRateRecovery.map { "HRR: \(String(format: "%.0f", $0)) bpm" }

        let descriptions = [vo2Max, heartRateRecovery].compactMap({ $0 })

        if descriptions.isEmpty {
            return "No Data"
        }
        return descriptions.joined(separator: "\n")
    }

    var vo2MaxFitnessLevel: FitnessLevel {
        guard let goal = HealthManager.shared.goalVO2MaxForUser(), let averageVO2Max else { return .unknown }

        if averageVO2Max < goal.2 {
            return .low
        } else if averageVO2Max < goal.1 {
            return .belowAverage
        } else if averageVO2Max < goal.0 {
            return .aboveAverage
        } else {
            return .high
        }
    }

    var level: FitnessLevel {
        if
            averageVO2Max == nil,
            averageHeartRateRecovery == nil
        {
            return .unknown
        }

        if score > 0.99 {
            return .high
        } else if score > 0.5 {
            return .aboveAverage
        } else if score > 0.01 {
            return .belowAverage
        } else {
            return .low
        }
    }
}
