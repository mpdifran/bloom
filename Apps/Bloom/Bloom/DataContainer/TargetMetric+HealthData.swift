//
//  TargetMetric+HealthData.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-18.
//

@preconcurrency import HealthKit
import DataContainer
import BloomFoundation

extension TargetMetric {

  var sampleTypes: [HKSampleType] {
    switch self {
    case .none:
      []
    case .calories:
      [HKQuantityType(.dietaryEnergyConsumed)]
    case .proteinIntake:
      [HKQuantityType(.dietaryProtein)]
    case .waterIntake:
      [HKQuantityType(.dietaryWater)]
    case .fiberIntake:
      [HKQuantityType(.dietaryFiber)]
    case .timeInDaylight:
      [HKQuantityType(.timeInDaylight)]
    case .meditationMinutes:
      [HKCategoryType(.mindfulSession)]
    case .exerciseMinutes:
      [HKWorkoutType.workoutType()]
    case .stepCount:
      [HKQuantityType(.stepCount)]
    case .walkingRunningDistance:
      [HKQuantityType(.distanceWalkingRunning)]
    case .runDistance, .runDuration, .bikeDistance, .bikeDuration:
      [HKWorkoutType.workoutType()]
    case .targetHeartRateZone1, .targetHeartRateZone2, .targetHeartRateZone3, .targetHeartRateZone4, .targetHeartRateZone5:
      [HKWorkoutType.workoutType()]
    @unknown default:
      fatalError("Unhandled TargetMetric case.")
    }
  }

  var defaultUnit: HKUnit {
    switch self {
    case .none:
        .count()
    case .calories:
        .largeCalorie()
    case .proteinIntake:
        .gram()
    case .waterIntake:
        .literUnit(with: .milli)
    case .fiberIntake:
        .gram()
    case .timeInDaylight:
        .minute()
    case .meditationMinutes:
        .minute()
    case .exerciseMinutes:
        .minute()
    case .stepCount:
        .count()
    case .walkingRunningDistance:
        .meterUnit(with: .kilo)
    case .runDistance:
        .meterUnit(with: .kilo)
    case .runDuration:
        .minute()
    case .bikeDistance:
        .meterUnit(with: .kilo)
    case .bikeDuration:
        .minute()
    case .targetHeartRateZone1, .targetHeartRateZone2, .targetHeartRateZone3, .targetHeartRateZone4, .targetHeartRateZone5:
        .minute()
    @unknown default:
      fatalError("Unhandled TargetMetric case.")
    }
  }

  var minHabitTarget: HKQuantity {
    switch self {
    case .none:
      return HKQuantity(unit: defaultUnit, doubleValue: 0)
    case .stepCount:
      return HKQuantity(unit: defaultUnit, doubleValue: 4000)
    case .waterIntake:
      return HKQuantity(unit: defaultUnit, doubleValue: 1000)
    case .fiberIntake:
      return HKQuantity(unit: defaultUnit, doubleValue: 14)
    case .walkingRunningDistance:
      return HKQuantity(unit: defaultUnit, doubleValue: 3)
    case .timeInDaylight:
      return HKQuantity(unit: defaultUnit, doubleValue: 5)
    case .meditationMinutes:
      return HKQuantity(unit: defaultUnit, doubleValue: 5)
    case .exerciseMinutes:
      return HKQuantity(unit: defaultUnit, doubleValue: 30)
    case .proteinIntake:
      return HKQuantity(unit: defaultUnit, doubleValue: 60)
    case .calories:
      return HKQuantity(unit: defaultUnit, doubleValue: 1200)
    case .runDistance:
      return HKQuantity(unit: defaultUnit, doubleValue: 1)
    case .runDuration:
      return HKQuantity(unit: defaultUnit, doubleValue: 10)
    case .bikeDistance:
      return HKQuantity(unit: defaultUnit, doubleValue: 5)
    case .bikeDuration:
      return HKQuantity(unit: defaultUnit, doubleValue: 15)
    case .targetHeartRateZone1, .targetHeartRateZone2:
      return HKQuantity(unit: defaultUnit, doubleValue: 10)
    case .targetHeartRateZone3, .targetHeartRateZone4:
      return HKQuantity(unit: defaultUnit, doubleValue: 5)
    case .targetHeartRateZone5:
      return HKQuantity(unit: defaultUnit, doubleValue: 2.5)
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
    case .fiberIntake:
      let fiberGoal = HealthGoalProvider.shared.recommendedMinDailyIntakeForFiber()?.doubleValue(for: .gram()) ?? 25
      return HKQuantityRange(unit: defaultUnit, range: fiberGoal...fiberGoal*2)
    case .walkingRunningDistance:
      return HKQuantityRange(unit: defaultUnit, range: 5...8)
    case .timeInDaylight:
      return HKQuantityRange(unit: defaultUnit, range: 20...30)
    case .meditationMinutes:
      return HKQuantityRange(unit: defaultUnit, range: 10...30)
    case .exerciseMinutes:
      return HKQuantityRange(unit: defaultUnit, range: 20...30)
    case .proteinIntake:
      return nil
    case .calories:
      return nil
    case .runDistance:
      return HKQuantityRange(unit: defaultUnit, range: 5...10)
    case .runDuration:
      return HKQuantityRange(unit: defaultUnit, range: 30...60)
    case .bikeDistance:
      return HKQuantityRange(unit: defaultUnit, range: 20...50)
    case .bikeDuration:
      return HKQuantityRange(unit: defaultUnit, range: 30...60)
    case .targetHeartRateZone1, .targetHeartRateZone2:
      return HKQuantityRange(unit: defaultUnit, range: 20...30)
    case .targetHeartRateZone3, .targetHeartRateZone4:
      return HKQuantityRange(unit: defaultUnit, range: 10...15)
    case .targetHeartRateZone5:
      return HKQuantityRange(unit: defaultUnit, range: 6...10)
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
    case .fiberIntake:
      NumberFormatter.noDecimalPlaces
    case .walkingRunningDistance:
      NumberFormatter.oneDecimalPlace
    case .timeInDaylight:
      NumberFormatter.noDecimalPlaces
    case .meditationMinutes:
      NumberFormatter.noDecimalPlaces
    case .exerciseMinutes:
      NumberFormatter.noDecimalPlaces
    case .proteinIntake:
      NumberFormatter.noDecimalPlaces
    case .calories:
      NumberFormatter.noDecimalPlaces
    case .runDistance, .bikeDistance:
      NumberFormatter.oneDecimalPlace
    case .runDuration, .bikeDuration:
      NumberFormatter.noDecimalPlaces
    case .targetHeartRateZone1, .targetHeartRateZone2, .targetHeartRateZone3, .targetHeartRateZone4, .targetHeartRateZone5:
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
    case .calories:
      return await HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietaryEnergyConsumed, dateRange: dateRange) ?? defaultQuantity
    case .proteinIntake:
      return await HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietaryProtein, dateRange: dateRange) ?? defaultQuantity
    case .waterIntake:
      return await HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietaryWater, dateRange: dateRange) ?? defaultQuantity
    case .fiberIntake:
      return await HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietaryFiber, dateRange: dateRange) ?? defaultQuantity
    case .timeInDaylight:
      return await HealthStoreFetcher.shared.fetchTotalQuantity(for: .timeInDaylight, dateRange: dateRange) ?? defaultQuantity
    case .meditationMinutes:
      return await HealthStoreFetcher.shared.fetchTotalMeditationMinutes(dateRange: dateRange)
    case .exerciseMinutes:
      return await HealthStoreFetcher.shared.fetchTotalQuantity(for: .appleExerciseTime, dateRange: dateRange) ?? defaultQuantity
    case .stepCount:
      return await HealthStoreFetcher.shared.fetchTotalQuantity(for: .stepCount, dateRange: dateRange) ?? defaultQuantity
    case .walkingRunningDistance:
      return await HealthStoreFetcher.shared.fetchTotalQuantity(for: .distanceWalkingRunning, dateRange: dateRange) ?? defaultQuantity
    case .runDistance:
      let workouts = await HealthStoreFetcher.shared.fetchWorkouts(activityType: .running, dateRange: dateRange)
      let totalDistance = workouts.sum { workout in
        workout.totalDistanceWalkingRunning?.doubleValue(for: defaultUnit) ?? 0
      }
      return HKQuantity(unit: defaultUnit, doubleValue: totalDistance)
    case .runDuration:
      let workouts = await HealthStoreFetcher.shared.fetchWorkouts(activityType: .running, dateRange: dateRange)
      let totalDuration = workouts.sum { $0.duration }
      return HKQuantity(unit: .second(), doubleValue: totalDuration)
    case .bikeDistance:
      let workouts = await HealthStoreFetcher.shared.fetchWorkouts(activityType: .cycling, dateRange: dateRange)
      let totalDistance = workouts.sum { workout in
        workout.totalDistanceCycling?.doubleValue(for: defaultUnit) ?? 0
      }
      return HKQuantity(unit: defaultUnit, doubleValue: totalDistance)
    case .bikeDuration:
      let workouts = await HealthStoreFetcher.shared.fetchWorkouts(activityType: .cycling, dateRange: dateRange)
      let totalDuration = workouts.sum { $0.duration }
      return HKQuantity(unit: .second(), doubleValue: totalDuration)
    case .targetHeartRateZone1:
      let reports = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)
      let distribution = reports.generateOverallDistribution()
      return distribution.zone1
    case .targetHeartRateZone2:
      let reports = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)
      let distribution = reports.generateOverallDistribution()
      return distribution.zone2
    case .targetHeartRateZone3:
      let reports = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)
      let distribution = reports.generateOverallDistribution()
      return distribution.zone3
    case .targetHeartRateZone4:
      let reports = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)
      let distribution = reports.generateOverallDistribution()
      return distribution.zone4
    case .targetHeartRateZone5:
      let reports = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)
      let distribution = reports.generateOverallDistribution()
      return distribution.zone5
    @unknown default:
      fatalError("Unhandled TargetMetric case.")
    }
  }

  func fetchCollatedDailyQuantity(unit: HKUnit, dateRange: DateRange) async -> [DateQuantitySample] {
    switch self {
    case .none:
      return []
    case .calories:
      return await HealthStoreFetcher.shared.fetchCollatedQuantity(for: .dietaryEnergyConsumed, unit: unit, dateRange: dateRange)
    case .proteinIntake:
      return await HealthStoreFetcher.shared.fetchCollatedQuantity(for: .dietaryProtein, unit: unit, dateRange: dateRange)
    case .waterIntake:
      return await HealthStoreFetcher.shared.fetchCollatedQuantity(for: .dietaryWater, unit: unit, dateRange: dateRange)
    case .fiberIntake:
      return await HealthStoreFetcher.shared.fetchCollatedQuantity(for: .dietaryFiber, unit: unit, dateRange: dateRange)
    case .timeInDaylight:
      return await HealthStoreFetcher.shared.fetchCollatedQuantity(for: .timeInDaylight, unit: unit, dateRange: dateRange)
    case .meditationMinutes:
      return await HealthStoreFetcher.shared.fetchCollatedMeditationMinutes(dateRange: dateRange)
    case .exerciseMinutes:
      return await HealthStoreFetcher.shared.fetchCollatedQuantity(for: .appleExerciseTime, unit: unit, dateRange: dateRange)
    case .stepCount:
      return await HealthStoreFetcher.shared.fetchCollatedQuantity(for: .stepCount, unit: unit, dateRange: dateRange)
    case .walkingRunningDistance:
      return await HealthStoreFetcher.shared.fetchCollatedQuantity(for: .distanceWalkingRunning, unit: unit, dateRange: dateRange)
    case .runDuration:
      let workouts = await HealthStoreFetcher.shared.fetchCollatedWorkouts(activityType: .running, dateRange: dateRange)
      return workouts.map {
        let total = $0.workouts.sum(keyPath: \.duration)
        return DateQuantitySample(date: $0.date, quantity: HKQuantity(unit: .second(), doubleValue: total))
      }
    case .runDistance:
      let workouts = await HealthStoreFetcher.shared.fetchCollatedWorkouts(activityType: .running, dateRange: dateRange)
      return workouts.map {
        let total = $0.workouts.sum(where: { $0.totalDistanceWalkingRunning?.doubleValue(for: unit) ?? 0 })
        return DateQuantitySample(date: $0.date, quantity: HKQuantity(unit: unit, doubleValue: total))
      }
    case .bikeDuration:
      let workouts = await HealthStoreFetcher.shared.fetchCollatedWorkouts(activityType: .cycling, dateRange: dateRange)
      return workouts.map {
        let total = $0.workouts.sum(keyPath: \.duration)
        return DateQuantitySample(date: $0.date, quantity: HKQuantity(unit: .second(), doubleValue: total))
      }
    case .bikeDistance:
      let workouts = await HealthStoreFetcher.shared.fetchCollatedWorkouts(activityType: .cycling, dateRange: dateRange)
      return workouts.map {
        let total = $0.workouts.sum(where: { $0.totalDistanceCycling?.doubleValue(for: unit) ?? 0 })
        return DateQuantitySample(date: $0.date, quantity: HKQuantity(unit: unit, doubleValue: total))
      }
    case .targetHeartRateZone1:
      let collatedReports = await HealthStoreFetcher.shared.fetchCollatedWorkoutHeartRateReports(dateRange: dateRange)
      return collatedReports.map { collatedReport in
        let overallDistribution = collatedReport.reports.generateOverallDistribution()
        let totalDuration = overallDistribution.zone1
        return DateQuantitySample(date: collatedReport.date, quantity: totalDuration)
      }
    case .targetHeartRateZone2:
      let collatedReports = await HealthStoreFetcher.shared.fetchCollatedWorkoutHeartRateReports(dateRange: dateRange)
      return collatedReports.map { collatedReport in
        let overallDistribution = collatedReport.reports.generateOverallDistribution()
        let totalDuration = overallDistribution.zone2
        return DateQuantitySample(date: collatedReport.date, quantity: totalDuration)
      }
    case .targetHeartRateZone3:
      let collatedReports = await HealthStoreFetcher.shared.fetchCollatedWorkoutHeartRateReports(dateRange: dateRange)
      return collatedReports.map { collatedReport in
        let overallDistribution = collatedReport.reports.generateOverallDistribution()
        let totalDuration = overallDistribution.zone3
        return DateQuantitySample(date: collatedReport.date, quantity: totalDuration)
      }
    case .targetHeartRateZone4:
      let collatedReports = await HealthStoreFetcher.shared.fetchCollatedWorkoutHeartRateReports(dateRange: dateRange)
      return collatedReports.map { collatedReport in
        let overallDistribution = collatedReport.reports.generateOverallDistribution()
        let totalDuration = overallDistribution.zone4
        return DateQuantitySample(date: collatedReport.date, quantity: totalDuration)
      }
    case .targetHeartRateZone5:
      let collatedReports = await HealthStoreFetcher.shared.fetchCollatedWorkoutHeartRateReports(dateRange: dateRange)
      return collatedReports.map { collatedReport in
        let overallDistribution = collatedReport.reports.generateOverallDistribution()
        let totalDuration = overallDistribution.zone5
        return DateQuantitySample(date: collatedReport.date, quantity: totalDuration)
      }
    @unknown default:
      fatalError("Unhandled TargetMetric case.")
    }
  }
}
