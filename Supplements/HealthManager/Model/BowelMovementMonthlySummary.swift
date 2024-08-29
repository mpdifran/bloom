//
//  BowelMovementMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-28.
//

import SwiftUI

private enum Constants {
    static let stoolTypeScoreMap = [
        1 : 0.5,
        2 : 0.75,
        3 : 1,
        4 : 1,
        5 : 0.75,
        6 : 0.5,
        7 : 0,
    ]
}

extension BowelMovementMonthlySummary {
    enum Rating {
        case unhealthy
        case concerning
        case acceptable
        case optimal

        var name: String {
            switch self {
            case .unhealthy:
                "Unhealthy"
            case .concerning:
                "Concerning"
            case .acceptable:
                "Acceptable"
            case .optimal:
                "Optimal"
            }
        }

        var color: Color {
            switch self {
            case .unhealthy:
                    .pink
            case .concerning:
                    .yellow
            case .acceptable:
                    .green
            case .optimal:
                    .coreSleep
            }
        }
    }
}

struct BowelMovementMonthlySummary: Sendable {
    let details: Details?
    let lastMonth: Details?

    var trend: VitalModel.Trend {
        guard let details, let lastMonth else { return .noTrend }

        return details.score < lastMonth.score ? .decreasing : .increasing
    }
}

extension BowelMovementMonthlySummary {
    struct Details: Sendable {
        let bowelMovements: [BowelMovement]
    }
}

extension BowelMovementMonthlySummary.Details {

    var score: Double {
        bowelMovements
            .compactMap({ bowelMovement in
                guard let score = Constants.stoolTypeScoreMap[bowelMovement.bristolStoolType] else { return nil }

                return score * bowelMovement.duration.scoreModifier
            })
            .average(keyPath: \.self)
    }

    var subtitle: String {
        guard let start = bowelMovements.min(keyPath: \.date) else {
            return "No Data"
        }

        let daySpan = (Calendar.current.dateComponents([.day], from: start, to: .now).day ?? 0) + 1

        let pace = Double(daySpan) / Double(bowelMovements.count)
        let paceFormat = pace.format(to: 1)

        return "Every \(paceFormat) \(paceFormat == "1" ? "Day" : "Days")"
    }

    var rating: BowelMovementMonthlySummary.Rating {
        if score < 0.5 {
            return .unhealthy
        } else if score < 0.7 {
            return .concerning
        } else if score < 0.9 {
            return .acceptable
        } else {
            return .optimal
        }
    }

    var timeOfDayDistribution: [Int : [BowelMovement]] {
        bowelMovements
            .grouped(by: { Calendar.current.component(.hour, from: $0.date) })
    }

    var stoolTypeDistribution: [Int : [BowelMovement]] {
        bowelMovements.grouped(by: { $0.bristolStoolType })
    }
}
