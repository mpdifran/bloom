//
//  BowelMovementMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-28.
//

import SwiftUI
import DataContainer

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
                    .vitalSevere
            case .concerning:
                    .vitalWarning
            case .acceptable:
                    .vitalGood
            case .optimal:
                    .vitalGreat
            }
        }
    }
}

struct BowelMovementMonthlySummary: Sendable {
    let details: Details?

    var barLevel: VitalModel.BarLevel? {
        guard
            let rating = details?.rating,
            let score = details?.score
        else { return nil }

        switch rating {
        case .unhealthy:
            return VitalModel.BarLevel(
                level: .low,
                proportion: score.scaledPercent(lower: 0, upper: 0.4)
            )
        case .concerning:
            return VitalModel.BarLevel(
                level: .medium,
                proportion: score.scaledPercent(lower: 0.4, upper: 0.6)
            )
        case .acceptable:
            return VitalModel.BarLevel(
                level: .high,
                proportion: score.scaledPercent(lower: 0.6, upper: 0.9)
            )
        case .optimal:
            return VitalModel.BarLevel(
                level: .optimal,
                proportion: score.scaledPercent(lower: 0.9, upper: 1)
            )
        }
    }
}

extension BowelMovementMonthlySummary {
    struct Details: Sendable {
        let bowelMovements: [BowelMovement]
    }
}

extension BowelMovementMonthlySummary.Details {

    var score: Double {
        // TODO: Incorporate frequency
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
                maxScore = score
            }
        }

        return maxIndex + 1
    }
}
