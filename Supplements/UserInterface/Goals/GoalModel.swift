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

    var dailyValue: Double {
        value / 7
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
            let workouts = await HealthManager.shared.fetchWorkouts(
                activityType: .yoga,
                dateRange: dateRange
            )
            let totalDuration = workouts.sum { $0.duration }
            return HKQuantity(unit: .second(), doubleValue: totalDuration)
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
        case .targetHeartRateZoneTimeZone12:
            let reports = await HealthManager.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)
            let distribution = reports.generateOverallDistribution()
            return distribution.zone1.sum(distribution.zone2, unit: .minute())
        case .targetHeartRateZoneTimeZone34:
            let reports = await HealthManager.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)
            let distribution = reports.generateOverallDistribution()
            return distribution.zone3.sum(distribution.zone4, unit: .minute())
        case .targetHeartRateZoneTimeZone5:
            let reports = await HealthManager.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)
            let distribution = reports.generateOverallDistribution()
            return distribution.zone5
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
        case .increaseWater:
            return await HealthManager.shared.fetchTotalSum(for: .dietaryWater, dateRange: dateRange) ?? defaultQuantity
        }

        return defaultQuantity
    }

    func fetchCollatedDailyQuantity(for dateRange: DateRange) async -> [DateQuantitySample] {
        switch measurement {
        case .timeInDaylight:
            return await HealthManager.shared.fetchCollatedQuantity(for: .timeInDaylight, unit: unit, dateRange: dateRange)
        case .walkRunDistance:
            return await HealthManager.shared.fetchCollatedQuantity(for: .distanceWalkingRunning, unit: unit, dateRange: dateRange)
        case .walkDuration:
            let workouts = await HealthManager.shared.fetchCollatedWorkouts(activityType: .walking, dateRange: dateRange)
            return workouts.map {
                let total = $0.workouts.sum(keyPath: \.duration)
                return DateQuantitySample(date: $0.date, quantity: .init(unit: .second(), doubleValue: total))
            }
        case .runDistance:
            let workouts = await HealthManager.shared.fetchCollatedWorkouts(activityType: .running, dateRange: dateRange)
            return workouts.map {
                let total = $0.workouts.sum(where: { $0.totalDistanceWalkingRunning.doubleValue(for: unit) })
                return DateQuantitySample(date: $0.date, quantity: .init(unit: unit, doubleValue: total))
            }
        case .runDuration:
            let workouts = await HealthManager.shared.fetchCollatedWorkouts(activityType: .running, dateRange: dateRange)
            return workouts.map {
                let total = $0.workouts.sum(keyPath: \.duration)
                return DateQuantitySample(date: $0.date, quantity: .init(unit: .second(), doubleValue: total))
            }
        case .bikeDistance:
            let workouts = await HealthManager.shared.fetchCollatedWorkouts(activityType: .cycling, dateRange: dateRange)
            return workouts.map {
                let total = $0.workouts.sum(where: { $0.totalDistanceCycling.doubleValue(for: unit) })
                return DateQuantitySample(date: $0.date, quantity: .init(unit: unit, doubleValue: total))
            }
        case .bikeDuration:
            let workouts = await HealthManager.shared.fetchCollatedWorkouts(activityType: .cycling, dateRange: dateRange)
            return workouts.map {
                let total = $0.workouts.sum(keyPath: \.duration)
                return DateQuantitySample(date: $0.date, quantity: .init(unit: .second(), doubleValue: total))
            }
        case .walkRunBikeDistance:
            let workouts = await HealthManager.shared.fetchCollatedWorkouts(
                activityTypes: [.walking, .running, .cycling],
                dateRange: dateRange
            )
            return workouts.map {
                let total = $0.workouts.sum(where: { $0.totalDistanceWalkingRunningCycling.doubleValue(for: unit) })
                return DateQuantitySample(date: $0.date, quantity: .init(unit: unit, doubleValue: total))
            }
        case .walkRunBikeDuration:
            let workouts = await HealthManager.shared.fetchCollatedWorkouts(
                activityTypes: [.walking, .running, .cycling],
                dateRange: dateRange
            )
            return workouts.map {
                let total = $0.workouts.sum(keyPath: \.duration)
                return DateQuantitySample(date: $0.date, quantity: .init(unit: .second(), doubleValue: total))
            }
        case .hikeDuration:
            let workouts = await HealthManager.shared.fetchCollatedWorkouts(activityType: .hiking, dateRange: dateRange)
            return workouts.map {
                let total = $0.workouts.sum(keyPath: \.duration)
                return DateQuantitySample(date: $0.date, quantity: .init(unit: .second(), doubleValue: total))
            }
        case .stepCount:
            return await HealthManager.shared.fetchCollatedQuantity(for: .stepCount, unit: unit, dateRange: dateRange)
        case .meditationMinutes:
            return await HealthManager.shared.fetchCollatedMeditationMinutes(dateRange: dateRange)
        case .bedtimeSoundLevels:
            break
        case .yogaWorkoutDuration:
            let workouts = await HealthManager.shared.fetchCollatedWorkouts(activityType: .yoga, dateRange: dateRange)
            return workouts.map {
                let total = $0.workouts.sum(keyPath: \.duration)
                return DateQuantitySample(date: $0.date, quantity: .init(unit: .second(), doubleValue: total))
            }
        case .casualSportWorkoutDuration:
            break
        case .intenseSportWorkoutDuration:
            break
        case .gymTrainingWorkoutDuration:
            break
        case .hiitWorkoutDuration:
            let workouts = await HealthManager.shared.fetchCollatedWorkouts(
                activityType: .highIntensityIntervalTraining,
                dateRange: dateRange
            )
            return workouts.map {
                let total = $0.workouts.sum(keyPath: \.duration)
                return DateQuantitySample(date: $0.date, quantity: .init(unit: .second(), doubleValue: total))
            }
        case .targetHeartRateZoneTimeZone12:
            let collatedReports = await HealthManager.shared.fetchCollatedWorkoutHeartRateReports(dateRange: dateRange)
            return collatedReports.map { collatedReport in
                let overallDistribution = collatedReport.reports.generateOverallDistribution()
                let totalDuration = overallDistribution.zone1.sum(overallDistribution.zone2, unit: unit)

                return DateQuantitySample(date: collatedReport.date, quantity: totalDuration)
            }
        case .targetHeartRateZoneTimeZone34:
            let collatedReports = await HealthManager.shared.fetchCollatedWorkoutHeartRateReports(dateRange: dateRange)
            return collatedReports.map { collatedReport in
                let overallDistribution = collatedReport.reports.generateOverallDistribution()
                let totalDuration = overallDistribution.zone3.sum(overallDistribution.zone4, unit: unit)

                return DateQuantitySample(date: collatedReport.date, quantity: totalDuration)
            }
        case .targetHeartRateZoneTimeZone5:
            let collatedReports = await HealthManager.shared.fetchCollatedWorkoutHeartRateReports(dateRange: dateRange)
            return collatedReports.map { collatedReport in
                let overallDistribution = collatedReport.reports.generateOverallDistribution()
                let totalDuration = overallDistribution.zone5

                return DateQuantitySample(date: collatedReport.date, quantity: totalDuration)
            }
        case .increaseProtein:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietaryProtein, unit: unit, dateRange: dateRange)
        case .increaseCarbs:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietaryCarbohydrates, unit: unit, dateRange: dateRange)
        case .increaseFat:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietaryFatTotal, unit: unit, dateRange: dateRange)
        case .increaseVitaminA:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietaryVitaminA, unit: unit, dateRange: dateRange)
        case .increaseVitaminB6:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietaryVitaminB6, unit: unit, dateRange: dateRange)
        case .increaseVitaminB12:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietaryVitaminB12, unit: unit, dateRange: dateRange)
        case .increaseVitaminC:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietaryVitaminC, unit: unit, dateRange: dateRange)
        case .increaseVitaminD:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietaryVitaminD, unit: unit, dateRange: dateRange)
        case .increaseVitaminE:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietaryVitaminE, unit: unit, dateRange: dateRange)
        case .increaseCalcium, .decreaseCalcium:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietaryCalcium, unit: unit, dateRange: dateRange)
        case .increaseIron, .decreaseIron:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietaryIron, unit: unit, dateRange: dateRange)
        case .increaseMagnesium, .decreaseMagnesium:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietaryMagnesium, unit: unit, dateRange: dateRange)
        case .increasePotassium, .decreasePotassium:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietaryPotassium, unit: unit, dateRange: dateRange)
        case .increaseSodium, .decreaseSodium:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietarySodium, unit: unit, dateRange: dateRange)
        case .increaseZinc, .decreaseZinc:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietaryZinc, unit: unit, dateRange: dateRange)
        case .decreaseSugar:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietarySugar, unit: unit, dateRange: dateRange)
        case .decreaseCaffeine:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietaryCaffeine, unit: unit, dateRange: dateRange)
        case .increaseFiber:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietaryFiber, unit: unit, dateRange: dateRange)
        case .increaseWater:
            return await HealthManager.shared.fetchCollatedQuantity(for: .dietaryWater, unit: unit, dateRange: dateRange)
        }
        return []
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
        case targetHeartRateZoneTimeZone12
        case targetHeartRateZoneTimeZone34
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
        case increaseWater

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
                Color.purple
            case .targetHeartRateZoneTimeZone12:
                .heartRateZone2
            case .targetHeartRateZoneTimeZone34:
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
            case .increaseWater:
                    .blue
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

        var isCumulative: Bool {
            switch self {
            case .timeInDaylight, .walkRunDistance, .walkDuration, .runDistance, .runDuration, .bikeDistance, .bikeDuration, .walkRunBikeDistance, .walkRunBikeDuration, .hikeDuration, .meditationMinutes, .yogaWorkoutDuration, .casualSportWorkoutDuration, .intenseSportWorkoutDuration, .gymTrainingWorkoutDuration, .hiitWorkoutDuration, .targetHeartRateZoneTimeZone12, .targetHeartRateZoneTimeZone34, .targetHeartRateZoneTimeZone5:
                true
            case .stepCount, .bedtimeSoundLevels, .increaseProtein, .increaseCarbs, .increaseFat, .increaseVitaminA, .increaseVitaminB6, .increaseVitaminB12, .increaseVitaminC, .increaseVitaminD, .increaseVitaminE, .increaseCalcium, .decreaseCalcium, .increaseIron, .decreaseIron, .increaseMagnesium, .decreaseMagnesium, .increasePotassium, .decreasePotassium, .increaseSodium, .decreaseSodium, .increaseZinc, .decreaseZinc, .decreaseSugar, .decreaseCaffeine, .increaseFiber, .increaseWater:
                false
            }
        }

        var sampleTypes: [HKSampleType] {
            switch self {
            case .timeInDaylight:
                [HKQuantityType(.timeInDaylight)]
            case .walkRunDistance:
                [HKQuantityType(.distanceWalkingRunning)]
            case .walkDuration, .runDistance, .runDuration, .bikeDistance, .bikeDuration, .walkRunBikeDistance, .walkRunBikeDuration, .hikeDuration, .yogaWorkoutDuration, .casualSportWorkoutDuration, .intenseSportWorkoutDuration, .gymTrainingWorkoutDuration, .hiitWorkoutDuration, .targetHeartRateZoneTimeZone12, .targetHeartRateZoneTimeZone34, .targetHeartRateZoneTimeZone5:
                [HKWorkoutType.workoutType()]
            case .stepCount:
                [HKQuantityType(.stepCount)]
            case .meditationMinutes:
                [HKCategoryType(.mindfulSession)]
            case .bedtimeSoundLevels:
                [HKQuantityType(.environmentalAudioExposure)]
            case .increaseProtein:
                [HKQuantityType(.dietaryProtein)]
            case .increaseCarbs:
                [HKQuantityType(.dietaryCarbohydrates)]
            case .increaseFat:
                [HKQuantityType(.dietaryFatTotal)]
            case .increaseVitaminA:
                [HKQuantityType(.dietaryVitaminA)]
            case .increaseVitaminB6:
                [HKQuantityType(.dietaryVitaminB6)]
            case .increaseVitaminB12:
                [HKQuantityType(.dietaryVitaminB12)]
            case .increaseVitaminC:
                [HKQuantityType(.dietaryVitaminC)]
            case .increaseVitaminD:
                [HKQuantityType(.dietaryVitaminD)]
            case .increaseVitaminE:
                [HKQuantityType(.dietaryVitaminE)]
            case .increaseCalcium, .decreaseCalcium:
                [HKQuantityType(.dietaryCalcium)]
            case .increaseIron, .decreaseIron:
                [HKQuantityType(.dietaryIron)]
            case .increaseMagnesium, .decreaseMagnesium:
                [HKQuantityType(.dietaryMagnesium)]
            case .increasePotassium, .decreasePotassium:
                [HKQuantityType(.dietaryPotassium)]
            case .increaseSodium, .decreaseSodium:
                [HKQuantityType(.dietarySodium)]
            case .increaseZinc, .decreaseZinc:
                [HKQuantityType(.dietaryZinc)]
            case .decreaseSugar:
                [HKQuantityType(.dietarySugar)]
            case .decreaseCaffeine:
                [HKQuantityType(.dietaryCaffeine)]
            case .increaseFiber:
                [HKQuantityType(.dietaryFiber)]
            case .increaseWater:
                [HKQuantityType(.dietaryWater)]
            }
        }
    }
}
