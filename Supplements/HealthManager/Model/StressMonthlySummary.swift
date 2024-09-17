//
//  StressMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-25.
//

import SwiftUI
import DataContainer

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
            case .low: .vitalGreat
            case .moderate: .vitalGood
            case .high: .vitalWarning
            case .severe: .vitalSevere
            }
        }
    }
}

struct StressMonthlySummary: Hashable {
    let details: Details
    let lastMonthDetails: Details

    var score: Double {
        details.internalScore?.scaledPercent(lower: 0.4, upper: 1) ?? 1
    }

    var trend: VitalModel.Trend {
        guard let lastMonth = lastMonthDetails.internalScore, let thisMonth = details.internalScore else { return .noTrend }

        return lastMonth > thisMonth  ? .increasing : .decreasing
    }
}

extension StressMonthlySummary {
    struct Details: Hashable {
        let avgHeartRateVariability: Double?
        let varHeartRateVariability: Double?
        let restingHeartRate: Double?
        let bloodPressureSystolic: Double?
        let bloodPressureDiastolic: Double?
    }
}

extension StressMonthlySummary.Details {

    var internalScore: Double? {
        let hrvScore = varHeartRateVariability?.scaledPercent(lower: 0, upper: 500)

        let (min, max) = HealthManager.shared.goalRestingHeartRateForUser()
        let rhrScore = restingHeartRate?.scaledPercent(lower: max + 10, upper: max)

        let bloodPressureScore: Double?
        if let bloodPressureSystolic, let bloodPressureDiastolic {
            let bloodPressureCategory = HealthManager.shared.bloodPressureCategory(
                systolic: bloodPressureSystolic,
                diastolic: bloodPressureDiastolic
            )
            bloodPressureScore = bloodPressureCategory.score
        } else {
            bloodPressureScore = nil
        }

        let components = [hrvScore, rhrScore, bloodPressureScore, bloodPressureScore].compactMap({ $0 })

        guard components.isNotEmpty else { return nil }

        return components.average(keyPath: \.self)
    }

    var subtitle: String? {
        let hrv = avgHeartRateVariability.map { "HRV: \($0.format()) ms" }
        let rhr = restingHeartRate.map { "RHR: \($0.format()) bpm" }

        let bloodPressure: String?
        if let bloodPressureSystolic, let bloodPressureDiastolic {
            bloodPressure = "\(bloodPressureSystolic.format())/\(bloodPressureDiastolic.format()) mmHg"
        } else {
            bloodPressure = nil
        }

        let compactEntries = [hrv, rhr, bloodPressure].compactMap({ $0 })

        guard compactEntries.isNotEmpty else { return nil }

        return compactEntries.joined(separator: "\n")
    }

    var level: StressMonthlySummary.Level? {
        guard let internalScore else { return nil }

        if internalScore < 0.4 {
            return .severe
        } else if internalScore < 0.7 {
            return .high
        } else if internalScore < 0.9 {
            return .moderate
        } else {
            return .low
        }
    }
}
