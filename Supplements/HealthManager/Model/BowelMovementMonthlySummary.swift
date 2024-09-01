//
//  BowelMovementMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-28.
//

import SwiftUI

private enum Constants {
    static let stoolTypeScoreMap = [
        1 : 0.7,
        2 : 0.95,
        3 : 1.1,
        4 : 1.1,
        5 : 0.95,
        6 : 0.7,
        7 : 0.3,
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
        let paceFormat = pace.format()

        if paceFormat == "1" {
            return "Once a Day"
        }
        if pace > 1 {
            return "Every \(paceFormat) Days"
        }

        return "\(1/pace)x a Day"
    }

    var rating: BowelMovementMonthlySummary.Rating {
        if score < 0.4 {
            return .unhealthy
        } else if score < 0.6 {
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

    func prioritizedBristolStoolType() -> Int {
        var scores = Array(repeating: 0.0, count: 7)

        for (index, bowelMovement) in self.bowelMovements.enumerated() {
            guard bowelMovement.bristolStoolType != 3 && bowelMovement.bristolStoolType != 4 else { continue }

            scores[bowelMovement.bristolStoolType - 1] += Double(index)
        }

        var maxIndex = 0
        var maxScore: Double = 0

        for (index, score) in scores.enumerated() {
            if score > maxScore {
                maxIndex = index
            }
        }

        return maxIndex + 1
    }
}
