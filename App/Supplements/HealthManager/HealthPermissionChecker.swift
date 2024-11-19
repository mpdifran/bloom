//
//  HealthPermissionChecker.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-10.
//

import Foundation
import HealthKit

final class HealthPermissionChecker: Sendable {
    static let shared = HealthPermissionChecker()

    let healthStore = HKHealthStore()

    private init() { }

    let bodyMeasurementTypes: Set<HKObjectType> = [
        HKCharacteristicType(.dateOfBirth),
        HKCharacteristicType(.biologicalSex)
    ]

    let activityTypes: Set<HKObjectType> = [
        HKObjectType.activitySummaryType(),
        HKQuantityType(.appleExerciseTime),
        HKQuantityType(.stepCount),
        HKQuantityType(.basalEnergyBurned),
        HKQuantityType(.activeEnergyBurned),
        HKObjectType.workoutType(),
        HKQuantityType(.distanceWalkingRunning)
    ]

    let heartTypes: Set<HKObjectType> = [
        HKQuantityType(.heartRateVariabilitySDNN),
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.vo2Max),
        HKQuantityType(.heartRate),
        HKQuantityType(.bloodPressureSystolic),
        HKQuantityType(.bloodPressureDiastolic),
        HKQuantityType(.heartRateRecoveryOneMinute),
    ]

    let writeHeartTypes: Set<HKSampleType> = [
        HKQuantityType(.bloodPressureSystolic),
        HKQuantityType(.bloodPressureDiastolic)
    ]

    let sleepTypes: Set<HKObjectType> = [
        HKCategoryType(.sleepAnalysis),
        HKQuantityType(.environmentalAudioExposure),
        HKQuantityType(.respiratoryRate),
        HKQuantityType(.appleSleepingWristTemperature),
    ]

    let nutritionTypes: Set<HKObjectType> = [
        HKQuantityType(.dietaryEnergyConsumed),
//        HKQuantityType(.dietaryBiotin),
//        HKQuantityType(.dietaryCaffeine),
//        HKQuantityType(.dietaryCalcium),
        HKQuantityType(.dietaryCarbohydrates),
//        HKQuantityType(.dietaryChloride),
//        HKQuantityType(.dietaryCholesterol),
//        HKQuantityType(.dietaryChromium),
//        HKQuantityType(.dietaryCopper),
//        HKQuantityType(.dietaryFatMonounsaturated),
//        HKQuantityType(.dietaryFatPolyunsaturated),
//        HKQuantityType(.dietaryFatSaturated),
        HKQuantityType(.dietaryFatTotal),
        HKQuantityType(.dietaryFiber),
//        HKQuantityType(.dietaryFolate),
//        HKQuantityType(.dietaryIodine),
//        HKQuantityType(.dietaryIron),
//        HKQuantityType(.dietaryMagnesium),
//        HKQuantityType(.dietaryManganese),
//        HKQuantityType(.dietaryMolybdenum),
//        HKQuantityType(.dietaryNiacin),
//        HKQuantityType(.dietaryPantothenicAcid),
//        HKQuantityType(.dietaryPhosphorus),
//        HKQuantityType(.dietaryPotassium),
        HKQuantityType(.dietaryProtein),
//        HKQuantityType(.dietaryRiboflavin),
//        HKQuantityType(.dietarySelenium),
//        HKQuantityType(.dietarySodium),
        HKQuantityType(.dietarySugar),
//        HKQuantityType(.dietaryThiamin),
//        HKQuantityType(.dietaryVitaminA),
//        HKQuantityType(.dietaryVitaminB12),
//        HKQuantityType(.dietaryVitaminB6),
//        HKQuantityType(.dietaryVitaminC),
//        HKQuantityType(.dietaryVitaminD),
//        HKQuantityType(.dietaryVitaminE),
//        HKQuantityType(.dietaryVitaminK),
        HKQuantityType(.dietaryWater),
//        HKQuantityType(.dietaryZinc)
    ]

    let writeNutritionTypes: Set<HKSampleType> = [
        HKQuantityType(.dietaryWater),
        HKQuantityType(.dietaryEnergyConsumed),
        HKQuantityType(.dietaryCarbohydrates),
        HKQuantityType(.dietaryFatTotal),
        HKQuantityType(.dietaryProtein)
    ]

    let menstrualTypes: Set<HKObjectType> = [
        HKCategoryType(.menstrualFlow)
    ]

    let writeMenstrualTypes: Set<HKSampleType> = [
        HKCategoryType(.menstrualFlow)
    ]

    let otherTypes: Set<HKObjectType> = [
        HKQuantityType(.timeInDaylight),
        HKCategoryType(.mindfulSession),
        HKCategoryType(.appleWalkingSteadinessEvent),
        HKQuantityType(.sixMinuteWalkTestDistance),
        HKQuantityType(.walkingDoubleSupportPercentage),
        HKQuantityType(.bodyFatPercentage),
        HKQuantityType(.bodyMass)
    ]

    let writeOtherTypes: Set<HKSampleType> = [
        HKQuantityType(.bodyMass)
    ]
}

extension HealthPermissionChecker {

    func writeTypes() -> Set<HKSampleType> {
        var set = Set<HKSampleType>()

        writeNutritionTypes.forEach { set.insert($0) }
        writeHeartTypes.forEach { set.insert($0) }
        writeMenstrualTypes.forEach { set.insert($0) }
        writeOtherTypes.forEach { set.insert($0) }

        return set
    }

    func readTypes() -> Set<HKObjectType> {
        var set = Set<HKObjectType>()

        bodyMeasurementTypes.forEach { set.insert($0) }
        activityTypes.forEach { set.insert($0) }
        heartTypes.forEach { set.insert($0) }
        sleepTypes.forEach { set.insert($0) }
        nutritionTypes.forEach { set.insert($0) }
        menstrualTypes.forEach { set.insert($0) }
        otherTypes.forEach { set.insert($0) }

        return set
    }
}

extension HealthPermissionChecker {

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
                print(error)
            }
        }
    }
}
