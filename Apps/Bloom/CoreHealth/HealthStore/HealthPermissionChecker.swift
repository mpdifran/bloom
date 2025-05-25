//
//  HealthPermissionChecker.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-10.
//

import Foundation
import HealthKit
internal import TelemetryDeck

public final class HealthPermissionChecker: Sendable {
  public static let shared = HealthPermissionChecker()

  public let healthStore = HKHealthStore()

  private init() { }

  public let bodyMeasurementTypes: Set<HKObjectType> = [
    HKCharacteristicType(.dateOfBirth),
    HKCharacteristicType(.biologicalSex),
    HKQuantityType(.height)
  ]

  public let activityTypes: Set<HKObjectType> = [
    HKObjectType.activitySummaryType(),
    HKQuantityType(.appleExerciseTime),
    HKQuantityType(.stepCount),
    HKQuantityType(.basalEnergyBurned),
    HKQuantityType(.activeEnergyBurned),
    HKObjectType.workoutType(),
    HKSeriesType.workoutRoute(),
    HKQuantityType(.distanceWalkingRunning)
  ]

  public let heartTypes: Set<HKObjectType> = [
    HKQuantityType(.heartRateVariabilitySDNN),
    HKQuantityType(.restingHeartRate),
    HKQuantityType(.vo2Max),
    HKQuantityType(.heartRate),
    HKQuantityType(.bloodPressureSystolic),
    HKQuantityType(.bloodPressureDiastolic),
    HKCorrelationType(.bloodPressure),
    HKQuantityType(.heartRateRecoveryOneMinute),
  ]

  public let writeHeartTypes: Set<HKSampleType> = [
    HKQuantityType(.bloodPressureSystolic),
    HKQuantityType(.bloodPressureDiastolic),
    HKCorrelationType(.bloodPressure)
  ]

  public let sleepTypes: Set<HKObjectType> = [
    HKCategoryType(.sleepAnalysis),
    HKQuantityType(.environmentalAudioExposure),
    HKQuantityType(.respiratoryRate),
    HKQuantityType(.appleSleepingWristTemperature),
  ]

  public let nutritionTypes: Set<HKObjectType> = [
    HKQuantityType(.dietaryEnergyConsumed),
    //        HKQuantityType(.dietaryBiotin),
    //        HKQuantityType(.dietaryCaffeine),
    HKQuantityType(.dietaryCalcium),
    HKQuantityType(.dietaryCarbohydrates),
    //        HKQuantityType(.dietaryChloride),
    HKQuantityType(.dietaryCholesterol),
    //        HKQuantityType(.dietaryChromium),
    //        HKQuantityType(.dietaryCopper),
    HKQuantityType(.dietaryFatMonounsaturated),
    HKQuantityType(.dietaryFatPolyunsaturated),
    HKQuantityType(.dietaryFatSaturated),
    HKQuantityType(.dietaryFatTotal),
    HKQuantityType(.dietaryFiber),
    //        HKQuantityType(.dietaryFolate),
    //        HKQuantityType(.dietaryIodine),
    HKQuantityType(.dietaryIron),
    HKQuantityType(.dietaryMagnesium),
    //        HKQuantityType(.dietaryManganese),
    //        HKQuantityType(.dietaryMolybdenum),
    //        HKQuantityType(.dietaryNiacin),
    //        HKQuantityType(.dietaryPantothenicAcid),
    //        HKQuantityType(.dietaryPhosphorus),
    HKQuantityType(.dietaryPotassium),
    HKQuantityType(.dietaryProtein),
    //        HKQuantityType(.dietaryRiboflavin),
    //        HKQuantityType(.dietarySelenium),
    HKQuantityType(.dietarySodium),
    HKQuantityType(.dietarySugar),
    //        HKQuantityType(.dietaryThiamin),
    HKQuantityType(.dietaryVitaminA),
    HKQuantityType(.dietaryVitaminB12),
    HKQuantityType(.dietaryVitaminB6),
    HKQuantityType(.dietaryVitaminC),
    HKQuantityType(.dietaryVitaminD),
    HKQuantityType(.dietaryVitaminE),
    //        HKQuantityType(.dietaryVitaminK),
    HKQuantityType(.dietaryWater),
    HKQuantityType(.dietaryZinc)
  ]

  public let writeNutritionTypes: Set<HKSampleType> = [
    HKQuantityType(.dietaryEnergyConsumed),
    HKQuantityType(.dietaryCalcium),
    HKQuantityType(.dietaryCarbohydrates),
    HKQuantityType(.dietaryCholesterol),
    HKQuantityType(.dietaryFatMonounsaturated),
    HKQuantityType(.dietaryFatPolyunsaturated),
    HKQuantityType(.dietaryFatSaturated),
    HKQuantityType(.dietaryFatTotal),
    HKQuantityType(.dietaryFiber),
    HKQuantityType(.dietaryIron),
    HKQuantityType(.dietaryMagnesium),
    HKQuantityType(.dietaryPotassium),
    HKQuantityType(.dietaryProtein),
    HKQuantityType(.dietarySodium),
    HKQuantityType(.dietarySugar),
    HKQuantityType(.dietaryVitaminA),
    HKQuantityType(.dietaryVitaminB12),
    HKQuantityType(.dietaryVitaminB6),
    HKQuantityType(.dietaryVitaminC),
    HKQuantityType(.dietaryVitaminD),
    HKQuantityType(.dietaryVitaminE),
    HKQuantityType(.dietaryWater),
    HKQuantityType(.dietaryZinc)
  ]

  public let menstrualTypes: Set<HKObjectType> = [
    HKCategoryType(.menstrualFlow)
  ]

  public let writeMenstrualTypes: Set<HKSampleType> = [
    HKCategoryType(.menstrualFlow)
  ]

  public let otherTypes: Set<HKObjectType> = [
    HKQuantityType(.timeInDaylight),
    HKCategoryType(.mindfulSession),
//    HKCategoryType(.appleWalkingSteadinessEvent),
//    HKQuantityType(.sixMinuteWalkTestDistance),
//    HKQuantityType(.walkingDoubleSupportPercentage),
    HKQuantityType(.bodyFatPercentage),
    HKQuantityType(.bodyMass)
  ]

  public let writeOtherTypes: Set<HKSampleType> = [
    HKQuantityType(.bodyMass)
  ]

  public let readWatchTypes: Set<HKObjectType> = [
    HKQuantityType(.heartRate),
    HKQuantityType(.activeEnergyBurned),
    HKQuantityType(.distanceWalkingRunning),
    HKQuantityType.workoutType(),
    HKObjectType.activitySummaryType()
  ]

  public let writeWatchTypes: Set<HKSampleType> = [
    HKQuantityType.workoutType()
  ]
}

public extension HealthPermissionChecker {

  func writeTypes() -> Set<HKSampleType> {
    var set = Set<HKSampleType>()

    #if os(iOS)
    writeNutritionTypes.forEach { set.insert($0) }
    writeHeartTypes.forEach { set.insert($0) }
    writeMenstrualTypes.forEach { set.insert($0) }
    writeOtherTypes.forEach { set.insert($0) }
    #elseif os(watchOS)
    writeWatchTypes.forEach { set.insert($0) }
    #endif

    return set
  }

  func readTypes() -> Set<HKObjectType> {
    var set = Set<HKObjectType>()

    #if os(iOS)
    bodyMeasurementTypes.forEach { set.insert($0) }
    activityTypes.forEach { set.insert($0) }
    heartTypes.forEach { set.insert($0) }
    sleepTypes.forEach { set.insert($0) }
    nutritionTypes.forEach { set.insert($0) }
    menstrualTypes.forEach { set.insert($0) }
    otherTypes.forEach { set.insert($0) }
    #elseif os(watchOS)
    readWatchTypes.forEach { set.insert($0) }
    #endif

    return set
  }
}

public extension HealthPermissionChecker {

  func checkAccessForAllTypes() async throws -> HKAuthorizationRequestStatus {
    try await checkAccess(readTypes: readTypes(), writeTypes: writeTypes())
  }

  func checkAccess(readTypes: Set<HKObjectType> = [], writeTypes: Set<HKSampleType> = []) async throws -> HKAuthorizationRequestStatus {
    guard readTypes.isNotEmpty else { return .unknown }

    return try await healthStore.getRequestStatusForAuthorization(
      toShare: writeTypes,
      read: readTypes
    )
  }

  func requestAccessIfNeeded() async {
    guard HKHealthStore.isHealthDataAvailable() else { return }

    let authStatus = try? await checkAccessForAllTypes()
    if authStatus == .shouldRequest {
      do {
        try await healthStore.requestAuthorization(toShare: writeTypes(), read: readTypes())
      } catch {
        TelemetryDeck.errorOccurred(
          id: "HealthPermissionChecker",
          category: .thrownException,
          message: error.localizedDescription
        )
        print(error)
      }
    }
  }
}
