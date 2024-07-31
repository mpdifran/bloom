//
//  BodyFatPercentageMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SwiftUI

extension BodyFatPercentageMonthlySummary {
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
            case .athlete, .fit: .coreSleep
            case .essentialFat, .healthy: .green
            case .high: .pink
            }
        }
    }
}

struct BodyFatPercentageMonthlySummary: Equatable {
    let bodyFatPercentage: Double?
    let lastMonthBodyFatPercentage: Double?
}

extension BodyFatPercentageMonthlySummary {

    var trend: VitalModel.Trend {
        guard let bodyFatPercentage, let lastMonthBodyFatPercentage else {
            return .noTrend
        }
        return bodyFatPercentage > lastMonthBodyFatPercentage ? .increasing : .decreasing
    }

    var subtitle: String {
        guard let bodyFatPercentage else { return "No Data" }

        return "Fat: \(String(format: "%.0f", bodyFatPercentage * 100))%"
    }

    var range: PercentageRange {
        guard
            let goal = HealthManager.shared.goalBodyFatPercentage(),
            let bodyFatPercentage
        else { return .unknown }

        let percent = bodyFatPercentage * 100

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
