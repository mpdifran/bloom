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
        7 : 0.2,
    ]
}

extension BowelMovementMonthlySummary {
    enum Rating {
        case unhealthy
        case concerning
        case regular
        case optimal

        var name: String {
            switch self {
            case .unhealthy:
                "Unhealthy"
            case .concerning:
                "Concerning"
            case .regular:
                "Regular"
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
            case .regular:
                    .vitalGood
            case .optimal:
                    .vitalGreat
            }
        }
    }
}

struct BowelMovementMonthlySummary: Sendable {
    let bowelMovements: [BowelMovementDTO]

    init(bowelMovements: [BowelMovementDTO]) {
        self.bowelMovements = bowelMovements

        self.calculateScore()
    }

    var barLevel: VitalModel.BarLevel? {
        guard bowelMovements.count >= 2 else { return nil }

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
        case .regular:
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

    private(set) var score: Double = 1
    private(set) var subtitle: String = ""
}

extension BowelMovementMonthlySummary {

    mutating func calculateScore() {
        var scores = [Double]()
        var previousBowelMovement: BowelMovementDTO?

        for bowelMovement in bowelMovements.sorted(keyPath: \.date) {
            guard let score = Constants.stoolTypeScoreMap[bowelMovement.bristolStoolType] else { continue }

            let typeScore = score * bowelMovement.duration.scoreModifier

            if let previousBowelMovement {
                let hours = bowelMovement.date.timeIntervalSince(previousBowelMovement.date) / 3600

                let intervalScore: Double
                if hours < 8 {
                    intervalScore = Double(hours).scaledPercent(lower: 4, upper: 8)
                } else if hours > 72 {
                    intervalScore = Double(hours).scaledPercent(lower: 120, upper: 72)
                } else {
                    intervalScore = 1
                }

                let average = [typeScore, intervalScore].average(keyPath: \.self)
                print("\(bowelMovement.date) Type Score: \(typeScore), intervalScore: \(intervalScore)")
                scores.append(average)
            } else {
                print("\(bowelMovement.date) Type Score: \(typeScore)")
                scores.append(typeScore)
            }

            previousBowelMovement = bowelMovement
        }

        self.score = scores.average(keyPath: \.self)
        self.subtitle = calculateSubtitle()
    }

    func calculateSubtitle() -> String {
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
            return .regular
        } else {
            return .optimal
        }
    }

    var timeOfDayDistribution: [Calendar.TimeOfDay : [BowelMovementDTO]] {
        bowelMovements
            .grouped(by: { Calendar.current.timeOfDay(for: $0.date) })
    }

    var stoolTypeDistribution: [Int : [BowelMovementDTO]] {
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

private extension BowelMovementMonthlySummary {

    struct BowelMovementIntervalStatistics {
        let averageIntervalHours: Double
        let standardDeviationIntervalHours: Double
    }

    func bowelMovementStatistics() -> BowelMovementIntervalStatistics? {
        var intervals = [Double]()
        var previousBowelMovement: BowelMovementDTO?

        for bowelMovement in bowelMovements.sorted(keyPath: \.date) {
            defer {
                previousBowelMovement = bowelMovement
            }

            guard
                let previousBowelMovement,
                let hours = Calendar.current.dateComponents([.hour], from: previousBowelMovement.date, to: bowelMovement.date).hour
            else { continue }

            intervals.append(Double(hours))
        }

        let averageInterval = intervals.average(keyPath: \.self)

        guard let standardDeviation = intervals.standardDeviation(keyPath: \.self) else { return nil }

        return BowelMovementIntervalStatistics(
            averageIntervalHours: averageInterval,
            standardDeviationIntervalHours: standardDeviation
        )
    }
}
