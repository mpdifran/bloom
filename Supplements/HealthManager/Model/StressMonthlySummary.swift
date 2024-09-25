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
    let lastMonthDetails: Details

    var score: Double {
        details.averageStressLevel?.scaledPercent(lower: -1, upper: 0.5) ?? 1
    }

    var trend: VitalModel.Trend {
        guard
            let lastMonth = lastMonthDetails.averageStressLevel,
            let thisMonth = details.averageStressLevel
        else { return .noTrend }

        return lastMonth > thisMonth  ? .increasing : .decreasing
    }
}

extension StressMonthlySummary {
    struct Details: Hashable, Sendable {
        let dateRange: DateRange
        let heartRateVariability: [DateQuantitySample]
        let restingHeartRate: [DateQuantitySample]
        let bloodPressureSystolic: HKQuantity?
        let bloodPressureDiastolic: HKQuantity?

        // TODO: Add sleep here as well

        init(
            dateRange: DateRange,
            heartRateVariability: [DateQuantitySample],
            restingHeartRate: [DateQuantitySample],
            bloodPressureSystolic: HKQuantity?,
            bloodPressureDiastolic: HKQuantity?
        ) {
            self.dateRange = dateRange
            self.heartRateVariability = heartRateVariability
            self.restingHeartRate = restingHeartRate
            self.bloodPressureSystolic = bloodPressureSystolic
            self.bloodPressureDiastolic = bloodPressureDiastolic

            self.calculateStressLevels()
        }

        private(set) var averageHeartRateVariability: Double? = nil
        private(set) var averageRestingHeartRate: Double? = nil
        private(set) var stressLevels = [DateStressScore]()
        private(set) var averageStressLevel: Double? = nil
    }

    struct DateStressScore: Hashable, Sendable, Identifiable {
        var id: Date { date }
        let date: Date
        let stressScore: Double

        var level: StressMonthlySummary.Level {
            StressMonthlySummary.Level(score: stressScore)
        }
    }
}

extension StressMonthlySummary.Details {

    mutating func calculateStressLevels() {
        let targetDateRange = DateRange.trailingMonthsFromDate(date: dateRange.end, numberOfMonths: 1)

        let bloodPressure = averageBloodPressureStressLevel()

        var stressScores = [StressMonthlySummary.DateStressScore]()

        Calendar.current.iterate(dateRange: targetDateRange, by: .init(day: 1)) { date in
            let referenceDate = Calendar.current.startOfDay(for: date)
            let hrvStressScore = hrvStressLevel(for: referenceDate)
            let rhrStressScore = rhrStressLevel(for: referenceDate)
            let allStressScores = [hrvStressScore, hrvStressScore, hrvStressScore, rhrStressScore, bloodPressure, bloodPressure].unwrap()

            stressScores.append(
                StressMonthlySummary.DateStressScore(
                    date: referenceDate,
                    stressScore: allStressScores.average(keyPath: \.self)
                )
            )
        }

        if heartRateVariability.isNotEmpty {
            self.averageHeartRateVariability = heartRateVariability.map({ $0.quantity.doubleValue(for: .millisecond()) }).average(keyPath: \.self)
        }
        if restingHeartRate.isNotEmpty {
            self.averageRestingHeartRate = restingHeartRate.map({ $0.quantity.doubleValue(for: .bpm()) }).average(keyPath: \.self)
        }
        self.stressLevels = stressScores
        if stressScores.isEmpty {
            self.averageStressLevel = nil
        } else {
            self.averageStressLevel = stressScores.average(keyPath: \.stressScore)
        }
    }

    func hrvStressLevel(for date: Date) -> Double? {
        let trailingMonthDateRange = DateRange.trailingMonthsFromDate(date: date, numberOfMonths: 1)
        let trailingMonthValues = heartRateVariability.compactMap({ (sample) -> Double? in
            guard trailingMonthDateRange.contains(date: sample.date) else { return nil }

            return sample.quantity.doubleValue(for: .millisecond())
        })

        guard
            let trailingMonthStdDev = trailingMonthValues.standardDeviation(keyPath: \.self),
            let currentSample = heartRateVariability.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
        else {
            return nil
        }

        let trailingMonthAverage = trailingMonthValues.average(keyPath: \.self)
        let value = currentSample.quantity.doubleValue(for: .millisecond())
        let lower = trailingMonthAverage - 2 * trailingMonthStdDev
        let upper = trailingMonthAverage + 2 * trailingMonthStdDev

        return value.scaledSymmetricalScore(lower: lower, upper: upper)
    }

    func rhrStressLevel(for date: Date) -> Double? {
        guard
            let currentSample = restingHeartRate.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
        else { return nil }

        let (min, max) = HealthManager.shared.goalRestingHeartRateForUser()

        let value = currentSample.quantity.doubleValue(for: .bpm())

        if value > max {
            return value.scaledPercent(lower: max, upper: max + 10) * -1
        } else {
            let range = max - min
            let lower = max - (range * 2)

            return value.scaledPercent(lower: max, upper: lower)
        }
    }

    func averageBloodPressureStressLevel() -> Double? {
        guard let bloodPressureSystolic, let bloodPressureDiastolic else { return nil }

        let bloodPressureCategory = HealthManager.shared.bloodPressureCategory(
            systolic: bloodPressureSystolic.doubleValue(for: .millimeterOfMercury()),
            diastolic: bloodPressureDiastolic.doubleValue(for: .millimeterOfMercury())
        )
        return bloodPressureCategory.stressScore
    }

    var subtitle: String? {
        let hrv: String?
        if heartRateVariability.isNotEmpty {
            let average = heartRateVariability.map({ $0.quantity.doubleValue(for: .millisecond()) }).average(keyPath: \.self)
            hrv = "HRV: \(average.format()) ms"
        } else {
            hrv = nil
        }

        let rhr: String?
        if restingHeartRate.isNotEmpty {
            let average = restingHeartRate.map({ $0.quantity.doubleValue(for: .bpm()) }).average(keyPath: \.self)
            rhr = "RHR: \(average.format()) bpm"
        } else {
            rhr = nil
        }


        let bloodPressure: String?
        if let bloodPressureSystolic, let bloodPressureDiastolic {
            let systolic = bloodPressureSystolic.doubleValue(for: .millimeterOfMercury())
            let diastolic = bloodPressureDiastolic.doubleValue(for: .millimeterOfMercury())
            bloodPressure = "\(systolic.format())/\(diastolic.format()) mmHg"
        } else {
            bloodPressure = nil
        }

        let compactEntries = [hrv, rhr, bloodPressure].compactMap({ $0 })

        guard compactEntries.isNotEmpty else { return nil }

        return compactEntries.joined(separator: "\n")
    }

    var level: StressMonthlySummary.Level? {
        guard let averageStressLevel else { return nil }

        return StressMonthlySummary.Level(score: averageStressLevel)
    }
}
