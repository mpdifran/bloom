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
        let twoMonthsHeartRateVariability: [DateQuantitySample]
        let restingHeartRate: [DateQuantitySample]
        let bloodPressureSystolic: [DateQuantitySample]
        let twoMonthsBloodPressureSystolic: [DateQuantitySample]
        let bloodPressureDiastolic: [DateQuantitySample]
        let twoMonthsBloodPressureDiastolic: [DateQuantitySample]

        // TODO: Add sleep here as well

        init(
            dateRange: DateRange,
            heartRateVariability: [DateQuantitySample],
            twoMonthsHeartRateVariability: [DateQuantitySample],
            restingHeartRate: [DateQuantitySample],
            bloodPressureSystolic: [DateQuantitySample],
            twoMonthsBloodPressureSystolic: [DateQuantitySample],
            bloodPressureDiastolic: [DateQuantitySample],
            twoMonthsBloodPressureDiastolic: [DateQuantitySample]
        ) {
            self.dateRange = dateRange
            self.heartRateVariability = heartRateVariability
            self.twoMonthsHeartRateVariability = twoMonthsHeartRateVariability
            self.restingHeartRate = restingHeartRate
            self.bloodPressureSystolic = bloodPressureSystolic
            self.twoMonthsBloodPressureSystolic = twoMonthsBloodPressureSystolic
            self.bloodPressureDiastolic = bloodPressureDiastolic
            self.twoMonthsBloodPressureDiastolic = twoMonthsBloodPressureDiastolic

            self.calculateStressLevels()
        }

        private(set) var averageHeartRateVariability: Double? = nil
        private(set) var averageRestingHeartRate: Double? = nil
        private(set) var averageSystolic: Double? = nil
        private(set) var averageDiastolic: Double? = nil
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
        let targetDateRange = DateRange.trailingMonths(from: dateRange.end, numberOfMonths: 1)

        var stressScores = [StressMonthlySummary.DateStressScore]()

        Calendar.current.iterate(dateRange: targetDateRange, by: .init(day: 1)) { date in
            let referenceDate = Calendar.current.startOfDay(for: date)

            let hrvStressScore = hrvStressLevel(for: referenceDate)
            let rhrStressScore = rhrStressLevel(for: referenceDate)
            let bloodPressureScore = bloodPressureStressLevel(for: referenceDate)

            let allStressScores = [
                hrvStressScore,
                hrvStressScore,
                hrvStressScore,
                rhrStressScore,
                bloodPressureScore,
                bloodPressureScore
            ].unwrap()

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
        if bloodPressureSystolic.isNotEmpty {
            self.averageSystolic = bloodPressureSystolic.map({ $0.quantity.doubleValue(for: .millimeterOfMercury()) }).average(keyPath: \.self)
        }
        if bloodPressureDiastolic.isNotEmpty {
            self.averageDiastolic = bloodPressureDiastolic.map({ $0.quantity.doubleValue(for: .millimeterOfMercury()) }).average(keyPath: \.self)
        }

        self.stressLevels = stressScores
        if stressScores.isEmpty {
            self.averageStressLevel = nil
        } else {
            self.averageStressLevel = stressScores.average(keyPath: \.stressScore)
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
        if bloodPressureSystolic.isNotEmpty, bloodPressureDiastolic.isNotEmpty {
            let systolicAverage = bloodPressureSystolic.map({ $0.quantity.doubleValue(for: .millimeterOfMercury()) }).average(keyPath: \.self)
            let diastolicAverage = bloodPressureDiastolic.map({ $0.quantity.doubleValue(for: .millimeterOfMercury()) }).average(keyPath: \.self)
            bloodPressure = "BP: \(systolicAverage.format())/\(diastolicAverage.format()) mmHg"
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
