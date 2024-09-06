//
//  MobilityMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-25.
//

import SwiftUI
import HealthKit

private extension Double {
    static let lowerDoubleSupportTime: Double = 0.4
    static let upperDoubleSupportTime: Double = 0.8
    static let lowerSixMinuteWalk: Double = 100
    static let upperSixMinuteWalk: Double = 500
    static let maxWalkingSteadiness: Double = 6
}

extension MobilityMonthlySummary {
    enum Status {
        case unknown
        case poor
        case concern
        case good
        case excellent

        var name: String {
            switch self {
            case .unknown: "Unknown"
            case .poor: "Poor"
            case .concern: "Concern"
            case .good: "Good"
            case .excellent: "Excellent"
            }
        }

        var color: Color {
            switch self {
            case .unknown: .gray
            case .poor: .vitalSevere
            case .concern: .vitalWarning
            case .good: .vitalGood
            case .excellent: .vitalGreat
            }
        }
    }
}

struct MobilityMonthlySummary: Equatable {
    let doubleSupportTimePercent: Double
    let sixMinuteWalkDistance: Double
    let walkingSteadiness: [HKCategoryValueAppleWalkingSteadinessEvent]
    let lastMonthDoubleSupportTimePercent: Double
    let lastMonthSixMinuteWalkDistance: Double
    let lastMonthWalkingSteadiness: [HKCategoryValueAppleWalkingSteadinessEvent]
}

extension MobilityMonthlySummary {

    var score: Double {
        internalScore.scaledPercent(lower: 0.5, upper: 0.9)
    }

    private var internalScore: Double {
        let doubleSupportScore = doubleSupportTimePercent.scaledPercent(
            lower: .upperDoubleSupportTime,
            upper: .lowerDoubleSupportTime
        )
        let walkingScore = sixMinuteWalkDistance.scaledPercent(lower: .lowerSixMinuteWalk, upper: .upperSixMinuteWalk)
        let steadinessEvent = Double(walkingSteadiness
            .map { event in
                switch event {
                case .initialLow: 1
                case .repeatLow: 2
                case .initialVeryLow: 3
                case .repeatVeryLow: 4
                default: 0
                }
            }
            .reduce(0) { $0 + $1 })
        let steadinessScore = steadinessEvent.scaledPercent(lower: .maxWalkingSteadiness, upper: 0) 

        return [doubleSupportScore, walkingScore, steadinessScore].average(keyPath: \.self)
    }

    var lastMonthScore: Double {
        let doubleSupportScore = lastMonthDoubleSupportTimePercent.scaledPercent(
            lower: .upperDoubleSupportTime,
            upper: .lowerDoubleSupportTime
        )
        let walkingScore = lastMonthSixMinuteWalkDistance.scaledPercent(lower: .lowerSixMinuteWalk, upper: .upperSixMinuteWalk)
        let steadinessEvent = Double(lastMonthWalkingSteadiness
            .map { event in
                switch event {
                case .initialLow: 1
                case .repeatLow: 2
                case .initialVeryLow: 3
                case .repeatVeryLow: 4
                default: 0
                }
            }
            .reduce(0) { $0 + $1 })
        let steadinessScore = steadinessEvent / .maxWalkingSteadiness

        return [doubleSupportScore, walkingScore, steadinessScore].average(keyPath: \.self)
    }

    var trend: VitalModel.Trend {
        internalScore > lastMonthScore ? .increasing : .decreasing
    }

    var subtitle: String {
        let doubleSupport = "Double Support: \(String(format: "%.0f", doubleSupportTimePercent * 100))%"
        let sixMinuteWalk = "6 Min Walk: \(String(format: "%.0f", sixMinuteWalkDistance))m"
        return [doubleSupport, sixMinuteWalk].joined(separator: "\n")
    }

    var status: Status {
        if internalScore < 0.5 {
            return .poor
        } else if internalScore < 0.7 {
            return .concern
        } else if internalScore < 0.9 {
            return .good
        } else {
            return .excellent
        }
    }
}
