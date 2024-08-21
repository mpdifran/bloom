//
//  GoalModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI
import HealthKit

struct GoalModel: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let systemImage: String
    let summary: String
    let dueDate: Date
    let metric: Metric
    let vitalKind: VitalModel.Kind

    init(
        id: UUID = UUID(),
        title: String,
        systemImage: String,
        summary: String,
        dueDate: Date,
        metric: Metric,
        vitalKind: VitalModel.Kind
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.summary = summary
        self.dueDate = dueDate
        self.metric = metric
        self.vitalKind = vitalKind
    }
}

extension GoalModel {
    struct Metric: Hashable, Codable {
        let value: Double
        let unitString: String
        let measurement: MeasurementMetric

        init(
            value: Double,
            unitString: String,
            measurement: MeasurementMetric
        ) {
            self.value = value
            self.unitString = unitString
            self.measurement = measurement
        }

        init(
            value: Double,
            unit: HKUnit,
            measurement: MeasurementMetric
        ) {
            self.value = value
            self.unitString = unit.unitString
            self.measurement = measurement
        }

        init(
            quantity: HKQuantity,
            unit: HKUnit,
            measurement: MeasurementMetric
        ) {
            self.value = quantity.doubleValue(for: unit)
            self.unitString = unit.unitString
            self.measurement = measurement
        }
    }
}

extension GoalModel.Metric {

    var targetQuantity: HKQuantity {
        HKQuantity(unit: HKUnit(from: unitString), doubleValue: value)
    }

    var unit: HKUnit {
        HKUnit(from: unitString)
    }

    func quantity(for dateRange: DateRange) async -> HKQuantity {
        let defaultQuantity = HKQuantity(unit: unit, doubleValue: 0)
        switch measurement {
        case .timeInDaylight:
            return await HealthManager.shared.fetchTotalSum(for: .timeInDaylight, dateRange: dateRange) ?? defaultQuantity
        case .walkRunDistance:
            return await HealthManager.shared.fetchTotalSum(for: .distanceWalkingRunning, dateRange: dateRange) ?? defaultQuantity
        case .walkDuration:
            let workouts = await HealthManager.shared.fetchWorkouts(activityType: .walking, dateRange: dateRange)
            let totalDuration = workouts.sum { $0.duration }
            return HKQuantity(unit: .second(), doubleValue: totalDuration)
        case .runDistance:
            let workouts = await HealthManager.shared.fetchWorkouts(activityType: .running, dateRange: dateRange)
            let totalDistance = workouts.sum { workout in
                workout.totalDistanceWalkingRunning.doubleValue(for: unit)
            }
            return HKQuantity(unit: unit, doubleValue: totalDistance)
        case .runDuration:
            let workouts = await HealthManager.shared.fetchWorkouts(activityType: .running, dateRange: dateRange)
            let totalDuration = workouts.sum { $0.duration }
            return HKQuantity(unit: .second(), doubleValue: totalDuration)
        case .bikeDistance:
            let workouts = await HealthManager.shared.fetchWorkouts(activityType: .cycling, dateRange: dateRange)
            let totalDistance = workouts.sum { $0.totalDistanceCycling.doubleValue(for: unit) }
            return HKQuantity(unit: unit, doubleValue: totalDistance)
        case .bikeDuration:
            let workouts = await HealthManager.shared.fetchWorkouts(activityType: .cycling, dateRange: dateRange)
            let totalDuration = workouts.sum { $0.duration }
            return HKQuantity(unit: .second(), doubleValue: totalDuration)
        case .walkRunBikeDistance:
            let workouts = await HealthManager.shared.fetchWorkouts(
                activityTypes: [.walking, .running, .cycling],
                dateRange: dateRange
            )
            let totalDistance = workouts.sum { $0.totalDistanceWalkingRunningCycling.doubleValue(for: unit) }
            return HKQuantity(unit: unit, doubleValue: totalDistance)
        case .walkRunBikeDuration:
            let workouts = await HealthManager.shared.fetchWorkouts(
                activityTypes: [.walking, .running, .cycling],
                dateRange: dateRange
            )
            let totalDuration = workouts.sum { $0.duration }
            return HKQuantity(unit: .second(), doubleValue: totalDuration)
        case .hikeDuration:
            let workouts = await HealthManager.shared.fetchWorkouts(
                activityType: .hiking,
                dateRange: dateRange
            )
            let totalDuration = workouts.sum { $0.duration }
            return HKQuantity(unit: .second(), doubleValue: totalDuration)
        case .stepCount:
            return await HealthManager.shared.fetchTotalSum(for: .stepCount, dateRange: dateRange) ?? defaultQuantity
        case .meditationMinutes:
            return await HealthManager.shared.fetchTotalMeditationMinutes(dateRange: dateRange)
        case .bedtimeSoundLevels:
            break
        case .yogaWorkoutDuration:
            break
        case .casualSportWorkoutDuration:
            break
        case .intenseSportWorkoutDuration:
            break
        case .gymTrainingWorkoutDuration:
            break
        case .hiitWorkoutDuration:
            let workouts = await HealthManager.shared.fetchWorkouts(
                activityTypes: [.highIntensityIntervalTraining],
                dateRange: dateRange
            )
            let totalDuration = workouts.sum { $0.duration }
            return HKQuantity(unit: .second(), doubleValue: totalDuration)
        case .targetHeartRateZoneTimeZone2:
            break
        case .targetHeartRateZoneTimeZone3:
            break
        case .targetHeartRateZoneTimeZone4:
            break
        case .targetHeartRateZoneTimeZone5:
            break
        case .increaseProtein:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryProtein, dateRange: dateRange) ?? defaultQuantity
        case .increaseCarbs:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryCarbohydrates, dateRange: dateRange) ?? defaultQuantity
        case .increaseFat:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryFatTotal, dateRange: dateRange) ?? defaultQuantity
        case .increaseVitaminA:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryVitaminA, dateRange: dateRange) ?? defaultQuantity
        case .increaseVitaminB6:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryVitaminB6, dateRange: dateRange) ?? defaultQuantity
        case .increaseVitaminB12:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryVitaminB12, dateRange: dateRange) ?? defaultQuantity
        case .increaseVitaminC:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryVitaminC, dateRange: dateRange) ?? defaultQuantity
        case .increaseVitaminD:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryVitaminD, dateRange: dateRange) ?? defaultQuantity
        case .increaseVitaminE:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryVitaminE, dateRange: dateRange) ?? defaultQuantity
        case .increaseCalcium, .decreaseCalcium:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryCalcium, dateRange: dateRange) ?? defaultQuantity
        case .increaseIron, .decreaseIron:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryIron, dateRange: dateRange) ?? defaultQuantity
        case .increaseMagnesium, .decreaseMagnesium:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryMagnesium, dateRange: dateRange) ?? defaultQuantity
        case .increasePotassium, .decreasePotassium:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryPotassium, dateRange: dateRange) ?? defaultQuantity
        case .increaseSodium, .decreaseSodium:
            return await HealthManager.shared.fetchTotalSum(for: .dietarySodium, dateRange: dateRange) ?? defaultQuantity
        case .increaseZinc, .decreaseZinc:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryZinc, dateRange: dateRange) ?? defaultQuantity
        case .decreaseSugar:
            return await HealthManager.shared.fetchTotalSum(for: .dietarySugar, dateRange: dateRange) ?? defaultQuantity
        case .decreaseCaffeine:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryCaffeine, dateRange: dateRange) ?? defaultQuantity
        case .increaseFiber:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryFiber, dateRange: dateRange) ?? defaultQuantity
        }

        return defaultQuantity
    }
}

extension GoalModel {
    enum MeasurementMetric: Codable {
        case timeInDaylight
        case walkRunDistance
        case walkDuration
        case runDistance
        case runDuration
        case bikeDistance
        case bikeDuration
        case walkRunBikeDistance
        case walkRunBikeDuration
        case stepCount
        case hikeDuration
        case meditationMinutes
        case bedtimeSoundLevels
        case yogaWorkoutDuration
        case casualSportWorkoutDuration
        case intenseSportWorkoutDuration
        case gymTrainingWorkoutDuration
        case hiitWorkoutDuration
        case targetHeartRateZoneTimeZone2
        case targetHeartRateZoneTimeZone3
        case targetHeartRateZoneTimeZone4
        case targetHeartRateZoneTimeZone5
        case increaseProtein
        case increaseCarbs
        case increaseFat
        case increaseVitaminA
        case increaseVitaminB6
        case increaseVitaminB12
        case increaseVitaminC
        case increaseVitaminD
        case increaseVitaminE
        case increaseCalcium
        case decreaseCalcium
        case increaseIron
        case decreaseIron
        case increaseMagnesium
        case decreaseMagnesium
        case increasePotassium
        case decreasePotassium
        case increaseSodium
        case decreaseSodium
        case increaseZinc
        case decreaseZinc
        case decreaseSugar
        case decreaseCaffeine
        case increaseFiber

        var color: Color {
            switch self {
            case .timeInDaylight:
                    .orange
            case .walkRunDistance, .runDistance, .bikeDistance, .walkRunBikeDistance, .stepCount, .hikeDuration:
                    .green
            case .walkDuration, .runDuration, .bikeDuration, .walkRunBikeDuration:
                    .pink
            case .meditationMinutes:
                    .remSleep
            case .bedtimeSoundLevels:
                    .yellow
            case .yogaWorkoutDuration:
                    .awakeSleep
            case .casualSportWorkoutDuration:
                    .blue
            case .intenseSportWorkoutDuration:
                    .orange
            case .gymTrainingWorkoutDuration, .hiitWorkoutDuration:
                    .purple
            case .targetHeartRateZoneTimeZone2:
                    .heartRateZone2
            case .targetHeartRateZoneTimeZone3:
                    .heartRateZone3
            case .targetHeartRateZoneTimeZone4:
                    .heartRateZone4
            case .targetHeartRateZoneTimeZone5:
                    .heartRateZone5
            case .increaseProtein:
                    .protein
            case .increaseCarbs:
                    .carbohydrates
            case .increaseFat:
                    .fat
            case .increaseVitaminA:
                    .vitaminA
            case .increaseVitaminB6:
                    .vitaminB6
            case .increaseVitaminB12:
                    .vitaminB12
            case .increaseVitaminC:
                    .vitaminC
            case .increaseVitaminD:
                    .vitaminD
            case .increaseVitaminE:
                    .vitaminE
            case .increaseCalcium, .decreaseCalcium:
                    .calcium
            case .increaseIron, .decreaseIron:
                    .iron
            case .increaseMagnesium, .decreaseMagnesium:
                    .magnesium
            case .increasePotassium, .decreasePotassium:
                    .potassium
            case .increaseSodium, .decreaseSodium:
                    .sodium
            case .increaseZinc, .decreaseZinc:
                    .zinc
            case .decreaseSugar:
                    .sugar
            case .decreaseCaffeine:
                    .caffeine
            case .increaseFiber:
                    .fiber
            }
        }

        var isDecrease: Bool {
            switch self {
            case .decreaseCalcium, 
                    .decreaseIron,
                    .decreaseMagnesium,
                    .decreasePotassium,
                    .decreaseSodium,
                    .decreaseZinc,
                    .decreaseSugar,
                    .decreaseCaffeine:
                return true
            default:
                return false
            }
        }
    }
}
