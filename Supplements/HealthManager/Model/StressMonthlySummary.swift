//
//  StressMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-25.
//

import SwiftUI
import DataContainer
import HealthKit
import BloomFoundation

private extension Double {
    static let hrvVariance: Double = 8
    static let rhrUpperThreadDiff: Double = 10
}

extension StressMonthlySummary {
    enum Level {
        case relaxed
        case mild
        case high
        case severe

        init(score: Double) {
            if score < -0.5 {
                self = .severe
            } else if score < 0 {
                self = .high
            } else if score < 0.5 {
                self = .mild
            } else {
                self = .relaxed
            }
        }

        var name: String {
            switch self {
            case .relaxed: "Relaxed"
            case .mild: "Mild"
            case .high: "High"
            case .severe: "Severe"
            }
        }

        var color: Color {
            switch self {
            case .relaxed: .vitalGreat
            case .mild: .vitalGood
            case .high: .vitalWarning
            case .severe: .vitalSevere
            }
        }
    }
}

struct StressMonthlySummary: Hashable, Sendable {
    let details: Details
    let lastMonthAverageSystolic: Double?
    let lastMonthAverageDiastolic: Double?

    var score: Double {
        details.averageStressLevel?.scaledPercent(lower: -1, upper: 0.5) ?? 1
    }

    var trend: VitalModel.Trend {
        return .noTrend
    }
}

extension StressMonthlySummary {
    struct Details: Hashable, Sendable {
        let dateRange: DateRange
        let heartRateVariability: [DateQuantitySample]
        let twoMonthsHeartRateVariability: [DateQuantitySample]
        let bloodPressureSystolic: [DateQuantitySample]
        let twoMonthsBloodPressureSystolic: [DateQuantitySample]
        let bloodPressureDiastolic: [DateQuantitySample]
        let twoMonthsBloodPressureDiastolic: [DateQuantitySample]
        let sleepAnalyses: [SleepAnalysis]

        // TODO: Add sleep here as well

        init(
            dateRange: DateRange,
            heartRateVariability: [DateQuantitySample],
            twoMonthsHeartRateVariability: [DateQuantitySample],
            bloodPressureSystolic: [DateQuantitySample],
            twoMonthsBloodPressureSystolic: [DateQuantitySample],
            bloodPressureDiastolic: [DateQuantitySample],
            twoMonthsBloodPressureDiastolic: [DateQuantitySample],
            sleepAnalyses: [SleepAnalysis]
        ) {
            self.dateRange = dateRange
            self.heartRateVariability = heartRateVariability
            self.twoMonthsHeartRateVariability = twoMonthsHeartRateVariability
            self.bloodPressureSystolic = bloodPressureSystolic
            self.twoMonthsBloodPressureSystolic = twoMonthsBloodPressureSystolic
            self.bloodPressureDiastolic = bloodPressureDiastolic
            self.twoMonthsBloodPressureDiastolic = twoMonthsBloodPressureDiastolic
            self.sleepAnalyses = sleepAnalyses

            self.calculateStressLevels()
        }

        private(set) var averageHeartRateVariability: Double? = nil
        private(set) var averageSystolic: Double? = nil
        private(set) var averageDiastolic: Double? = nil
        private(set) var averageSleepScore: Double? = nil
        private(set) var stressLevels = [DateStressScore]()
        private(set) var averageStressLevel: Double? = nil
        private(set) var averageBloodPressureStressLevel: Double? = nil
        private(set) var averageHeartRateVariabilityStressLevel: Double? = nil
        private(set) var averageSleepStressLevel: Double? = nil
    }

    struct DateStressScore: Hashable, Sendable, Identifiable {
        var id: Date { date }
        let date: Date
        let stressScore: Double
        let bloodPressureStressScore: Double
        let hrvStressScore: Double
        let sleepStressScore: Double

        var level: StressMonthlySummary.Level {
            StressMonthlySummary.Level(score: stressScore)
        }

        var bloodPressureLevel: StressMonthlySummary.Level {
            StressMonthlySummary.Level(score: bloodPressureStressScore)
        }

        var hrvLevel: StressMonthlySummary.Level {
            StressMonthlySummary.Level(score: hrvStressScore)
        }

        var sleepLevel: StressMonthlySummary.Level {
            StressMonthlySummary.Level(score: sleepStressScore)
        }
    }
}

extension StressMonthlySummary.Details {

    mutating func calculateStressLevels() {
        let targetDateRange = DateRange.trailingMonths(from: dateRange.end, numberOfMonths: 1)

        var stressScores = [StressMonthlySummary.DateStressScore]()

        Calendar.current.iterate(dateRange: targetDateRange, by: .init(day: 1)) { date in
            let referenceDate = Calendar.current.startOfDay(for: date)

            let hrvStressScore = hrvStressLevel(for: referenceDate)
//            let rhrStressScore = rhrStressLevel(for: referenceDate)
            let bloodPressureScore = bloodPressureStressLevel(for: referenceDate)
            let sleepStressScore = sleepStressLevel(for: referenceDate)

            let allStressScores = [
                hrvStressScore,
//                rhrStressScore,
                bloodPressureScore,
                sleepStressScore
            ].unwrap()

//            print("STRESS DEBUG \(referenceDate) HRV: \(hrvStressScore), RHR: \(rhrStressScore), BP: \(bloodPressureScore), SLEEP: \(sleepStressScore)")

            stressScores.append(
                StressMonthlySummary.DateStressScore(
                    date: referenceDate,
                    stressScore: allStressScores.average(keyPath: \.self),
                    bloodPressureStressScore: bloodPressureScore ?? 0,
                    hrvStressScore: hrvStressScore ?? 0,
                    sleepStressScore: sleepStressScore ?? 0
                )
            )
        }

        if heartRateVariability.isNotEmpty {
            self.averageHeartRateVariability = heartRateVariability.map({ $0.quantity.doubleValue(for: .millisecond()) }).average(keyPath: \.self)
        }
        if bloodPressureSystolic.isNotEmpty {
            self.averageSystolic = bloodPressureSystolic.map({ $0.quantity.doubleValue(for: .millimeterOfMercury()) }).average(keyPath: \.self)
        }
        if bloodPressureDiastolic.isNotEmpty {
            self.averageDiastolic = bloodPressureDiastolic.map({ $0.quantity.doubleValue(for: .millimeterOfMercury()) }).average(keyPath: \.self)
        }
        if sleepAnalyses.isNotEmpty {
            self.averageSleepScore = sleepAnalyses.average(keyPath: \.overallScoreDouble)
        }

        self.stressLevels = stressScores
        if stressScores.isNotEmpty {
            self.averageStressLevel = stressScores.average(keyPath: \.stressScore)
            self.averageBloodPressureStressLevel = stressScores.average(keyPath: \.bloodPressureStressScore)
            self.averageHeartRateVariabilityStressLevel = stressScores.average(keyPath: \.hrvStressScore)
            self.averageSleepStressLevel = stressScores.average(keyPath: \.sleepStressScore)
        }
    }

    func hrvStressLevel(for date: Date) -> Double? {
        let trailingMonthDateRange = DateRange.trailingMonths(from: date, numberOfMonths: 1)
        let trailingMonthValues = twoMonthsHeartRateVariability.compactMap({ (sample) -> Double? in
            guard trailingMonthDateRange.contains(date: sample.date) else { return nil }

            return sample.quantity.doubleValue(for: .millisecond())
        })

        guard
            let trailingMonthStdDev = trailingMonthValues.standardDeviation(keyPath: \.self),
            let currentSample = twoMonthsHeartRateVariability.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
        else {
            return nil
        }

        let trailingMonthAverage = trailingMonthValues.average(keyPath: \.self)
        let value = currentSample.quantity.doubleValue(for: .millisecond())
        let lower = trailingMonthAverage - 2 * trailingMonthStdDev
        let upper = trailingMonthAverage + 2 * trailingMonthStdDev

        return value.scaledSymmetricalScore(lower: lower, upper: upper)
    }

    func bloodPressureStressLevel(for date: Date) -> Double? {
        let trailingDateRange = DateRange.trailingMonths(from: date, numberOfMonths: 1)

        let trailingSystolicValues = twoMonthsBloodPressureSystolic.compactMap { (sample) -> Double? in
            guard trailingDateRange.contains(date: sample.date) else { return nil }

            return sample.quantity.doubleValue(for: .millimeterOfMercury())
        }

        let trailingDiastolicValues = twoMonthsBloodPressureDiastolic.compactMap { (sample) -> Double? in
            guard trailingDateRange.contains(date: sample.date) else { return nil }

            return sample.quantity.doubleValue(for: .millimeterOfMercury())
        }

        guard trailingSystolicValues.isNotEmpty, trailingDiastolicValues.isNotEmpty else { return nil }

        let bloodPressureStressScore = HealthManager.shared.bloodPressureStressScore(
            systolic: trailingSystolicValues.average(keyPath: \.self),
            diastolic: trailingDiastolicValues.average(keyPath: \.self)
        )

        return bloodPressureStressScore
    }

    func sleepStressLevel(for date: Date) -> Double? {
        guard
            let sleepAnalysis = sleepAnalyses.first(where: { Calendar.current.isDate($0.endDate, inSameDayAs: date) })
        else { return nil }

        let score = sleepAnalysis.overallScoreDouble.scaledSymmetricalScore(lower: 5, upper: 10)

//        print("SLEEP STRESS DEBUG \(sleepAnalysis.endDate) Sleep score: \(sleepAnalysis.overallScoreDouble.format(using: .oneDecimalPlace)) Score: \(score.format(using: .twoDecimalPlaces))")

        return score
    }

    var subtitle: String? {
        let hrv: String?
        if heartRateVariability.isNotEmpty {
            let average = heartRateVariability.map({ $0.quantity.doubleValue(for: .millisecond()) }).average(keyPath: \.self)
            hrv = "HRV: \(average.format()) ms"
        } else {
            hrv = nil
        }

        let bloodPressure: String?
        if bloodPressureSystolic.isNotEmpty, bloodPressureDiastolic.isNotEmpty {
            let systolicAverage = bloodPressureSystolic.map({ $0.quantity.doubleValue(for: .millimeterOfMercury()) }).average(keyPath: \.self)
            let diastolicAverage = bloodPressureDiastolic.map({ $0.quantity.doubleValue(for: .millimeterOfMercury()) }).average(keyPath: \.self)
            bloodPressure = "BP: \(systolicAverage.format())/\(diastolicAverage.format()) mmHg"
        } else {
            bloodPressure = nil
        }

        let compactEntries = [hrv, bloodPressure].compactMap({ $0 })

        guard compactEntries.isNotEmpty else { return nil }

        return compactEntries.joined(separator: "\n")
    }

    var level: StressMonthlySummary.Level? {
        guard let averageStressLevel else { return nil }

        return StressMonthlySummary.Level(score: averageStressLevel)
    }
}
