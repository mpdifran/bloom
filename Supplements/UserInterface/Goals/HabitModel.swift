//
//  HabitModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-09.
//

import SwiftUI
import HealthKit

struct HabitModel: Identifiable, Hashable, Codable {
    let id: UUID
    let measurement: MeasurementMetric
    var value: Double

    init(
        id: UUID = UUID(),
        measurement: MeasurementMetric,
        value: Double
    ) {
        self.id = id
        self.measurement = measurement
        self.value = value
    }
}

extension HabitModel {

    var name: String {
        measurement.name
    }

    var systemImage: String {
        measurement.systemImage
    }

    var color: Color {
        measurement.color
    }

    var unit: HKUnit {
        measurement.unit
    }

    var targetDisplayString: String {
        let quantity = HKQuantity(unit: unit, doubleValue: value)
        return quantity.displayString(for: unit)
    }
}

extension HabitModel {
    enum MeasurementMetric: Identifiable, Codable, CaseIterable {
        var id: Self { self }

        case stepCount
        case waterIntake
        case walkingRunningDistance
        case timeInDaylight
    }
}

extension HabitModel.MeasurementMetric {

    var name: String {
        switch self {
        case .stepCount: "Steps"
        case .waterIntake: "Water Intake"
        case .walkingRunningDistance: "Walking + Running Distance"
        case .timeInDaylight: "Time in Daylight"
        }
    }

    var systemImage: String {
        switch self {
        case .stepCount: "figure.walk"
        case .waterIntake: "waterbottle"
        case .walkingRunningDistance: "figure.walk"
        case .timeInDaylight: "sun.max.fill"
        }
    }

    var color: Color {
        switch self {
        case .stepCount: .mutedGreen
        case .waterIntake: .mutedBlue
        case .walkingRunningDistance: .mutedGreen
        case .timeInDaylight: .mutedOrange
        }
    }

    var unit: HKUnit {
        switch self {
        case .stepCount: .count()
        case .waterIntake: .literUnit(with: .milli)
        case .walkingRunningDistance: .meterUnit(with: .kilo)
        case .timeInDaylight: .minute()
        }
    }

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
        }
    }
}

extension HabitModel.MeasurementMetric {

    func quantity(for dateRange: DateRange) async -> HKQuantity {
        let defaultQuantity = HKQuantity(unit: unit, doubleValue: 0)
        switch self {
        case .stepCount:
            return await HealthManager.shared.fetchTotalSum(for: .stepCount, dateRange: dateRange) ?? defaultQuantity
        case .waterIntake:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryWater, dateRange: dateRange) ?? defaultQuantity
        case .walkingRunningDistance:
            return await HealthManager.shared.fetchTotalSum(for: .distanceWalkingRunning, dateRange: dateRange) ?? defaultQuantity
        case .timeInDaylight:
            return await HealthManager.shared.fetchTotalSum(for: .timeInDaylight, dateRange: dateRange) ?? defaultQuantity
        }
    }
}
