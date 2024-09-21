//
//  TargetMetric+HealthData.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-18.
//

import HealthKit
import DataContainer
import BloomFoundation

extension TargetMetric {

    var sampleTypes: [HKSampleType] {
        switch self {
        case .none:
            []
        case .stepCount:
            [HKQuantityType(.stepCount)]
        case .waterIntake:
            [HKQuantityType(.dietaryWater)]
        case .walkingRunningDistance:
            [HKQuantityType(.distanceWalkingRunning)]
        case .timeInDaylight:
            [HKQuantityType(.timeInDaylight)]
        @unknown default:
            fatalError("Unhandled TargetMetric case.")
        }
    }

    var defaultUnit: HKUnit {
        switch self {
        case .none:
                .count()
        case .stepCount:
                .count()
        case .waterIntake:
                .literUnit(with: .milli)
        case .walkingRunningDistance:
                .meterUnit(with: .kilo)
        case .timeInDaylight:
                .minute()
        }
    }

    var minHabitTarget: HKQuantity? {
        switch self {
        case .none:
            return nil
        case .stepCount:
            return HKQuantity(unit: defaultUnit, doubleValue: 5000) // Maybe 4000
        case .waterIntake:
            return HKQuantity(unit: defaultUnit, doubleValue: 250)
        case .walkingRunningDistance:
            return HKQuantity(unit: defaultUnit, doubleValue: 0.5)
        case .timeInDaylight:
            return HKQuantity(unit: defaultUnit, doubleValue: 5)
        @unknown default:
            fatalError("Unhandled TargetMetric case.")
        }
    }

    var idealRange: HKQuantityRange? {
        switch self {
        case .none:
            return nil
        case .stepCount:
            return HKQuantityRange(unit: defaultUnit, range: 7000...10000)
        case .waterIntake:
            return HKQuantityRange(unit: defaultUnit, range: 1750...3000)
        case .walkingRunningDistance:
            return HKQuantityRange(unit: defaultUnit, range: 5...8)
        case .timeInDaylight:
            return HKQuantityRange(unit: defaultUnit, range: 20...30)
        @unknown default:
            fatalError("Unhandled TargetMetric case.")
        }
    }

    var preferredFormatter: NumberFormatter {
        switch self {
        case .none:
            NumberFormatter.noDecimalPlaces
        case .stepCount:
            NumberFormatter.noDecimalPlaces
        case .waterIntake:
            NumberFormatter.noDecimalPlaces
        case .walkingRunningDistance:
            NumberFormatter.oneDecimalPlace
        case .timeInDaylight:
            NumberFormatter.noDecimalPlaces
        @unknown default:
            fatalError("Unhandled TargetMetric case.")
        }
    }
}

extension TargetMetric {

    func fetchDailyAverage(unit: HKUnit, dateRange: DateRange) async -> HKQuantity {
        let samples = await fetchCollatedDailyQuantity(unit: unit, dateRange: dateRange)

        let average = samples
            .map({ $0.quantity.doubleValue(for: unit) })
            .average(keyPath: \.self)

        return HKQuantity(unit: unit, doubleValue: average)
    }

    func fetchTotalQuantity(for dateRange: DateRange) async -> HKQuantity {
        let defaultQuantity = HKQuantity(unit: defaultUnit, doubleValue: 0)
        switch self {
        case .none:
            return defaultQuantity
        case .stepCount:
            return await HealthManager.shared.fetchTotalSum(for: .stepCount, dateRange: dateRange) ?? defaultQuantity
        case .waterIntake:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryWater, dateRange: dateRange) ?? defaultQuantity
        case .walkingRunningDistance:
            return await HealthManager.shared.fetchTotalSum(for: .distanceWalkingRunning, dateRange: dateRange) ?? defaultQuantity
        case .timeInDaylight:
            return await HealthManager.shared.fetchTotalSum(for: .timeInDaylight, dateRange: dateRange) ?? defaultQuantity
        @unknown default:
            fatalError("Unhandled TargetMetric case.")
        }
    }

    func fetchCollatedDailyQuantity(unit: HKUnit, dateRange: DateRange) async -> [DateQuantitySample] {
        switch self {
        case .none:
            return []
        case .stepCount:
            return await HealthManager.shared.fetchCollatedQuantity(for: .stepCount, unit: unit, dateRange: dateRange)
        case .waterIntake:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietaryWater, unit: unit, dateRange: dateRange)
        case .walkingRunningDistance:
            return await HealthManager.shared.fetchCollatedQuantity(for: .distanceWalkingRunning, unit: unit, dateRange: dateRange)
        case .timeInDaylight:
            return await HealthManager.shared.fetchCollatedQuantity(for: .timeInDaylight, unit: unit, dateRange: dateRange)
        @unknown default:
            fatalError("Unhandled TargetMetric case.")
        }
    }
}
