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
}

extension TargetMetric {

    func fetchTotalQuantity(for dateRange: DateRange) async -> HKQuantity? {
        switch self {
        case .stepCount:
            return await HealthManager.shared.fetchTotalSum(for: .stepCount, dateRange: dateRange)
        case .waterIntake:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryWater, dateRange: dateRange)
        case .walkingRunningDistance:
            return await HealthManager.shared.fetchTotalSum(for: .distanceWalkingRunning, dateRange: dateRange)
        case .timeInDaylight:
            return await HealthManager.shared.fetchTotalSum(for: .timeInDaylight, dateRange: dateRange)
        @unknown default:
            fatalError("Unhandled TargetMetric case.")
        }
    }

    func fetchCollatedDailyQuantity(unit: HKUnit, dateRange: DateRange) async -> [DateQuantitySample] {
        switch self {
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
