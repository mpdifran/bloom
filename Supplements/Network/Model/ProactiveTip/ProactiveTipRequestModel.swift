//
//  ProactiveTipRequestModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-12.
//

import Foundation

struct ProactiveTipRequestModel: Codable {
    let stressMonthlySummary: StressSummary?
    let nutritionMonthlySummary: NutritionSummary?
    let cardioFitnessSummary: CardioFitnessMonthlySummary?
    let sleepVitalsMonthlySummary: SleepVitalsMonthlySummary?
    let activityLevelMonthlySummary: ActivityLevelSummary?
    let chatHistory: [ChatMessageHistory]
}

extension ProactiveTipRequestModel {
    struct StressSummary: Codable {
        let stressLevel: String?
        let averageHeartRateVariability: Double?
        let varianceHeartRateVariability: Double?
        let averageRestingHeartRate: Double?
        let averageBloodPressureSystolic: Double?
        let averageBloodPressureDiastolic: Double?
    }

    struct NutritionSummary: Codable {
        let averageBasalEnergyBurnedCalories: Double?
        let averageActiveEnergyBurnedCalories: Double?
        let averageDietaryEnergyConsumedCalories: Double?
        let averageProteinGrams: Double?
        let averageCarbohydratesGrams: Double?
        let averageFatGrams: Double?
        let averageSugarGrams: Double?
        let averageVitaminAMicrograms: Double?
        let averageVitaminB6Milligrams: Double?
        let averageVitaminB12Micrograms: Double?
        let averageVitaminCMilligrams: Double?
        let averageVitaminDMicrograms: Double?
        let averageVitaminEMilligrams: Double?
    }
}
