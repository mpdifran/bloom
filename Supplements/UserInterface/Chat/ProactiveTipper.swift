//
//  ProactiveTipper.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-07.
//

import Foundation
import HealthKit

final actor ProactiveTipper {
    static let shared = ProactiveTipper()

    private init() { }
}

extension ProactiveTipper {

    func sendProactiveTip() async {
        let chatHistory = ChatViewModel.shared.networkChatHistory

        let stressSummary = ProactiveTipRequestModel.StressSummary(
            stressLevel: VitalsViewModel.shared.stressSummary?.level.name,
            averageHeartRateVariability: VitalsViewModel.shared.stressSummary?.avgHeartRateVariability,
            varianceHeartRateVariability: VitalsViewModel.shared.stressSummary?.varHeartRateVariability,
            averageRestingHeartRate: VitalsViewModel.shared.stressSummary?.restingHeartRate,
            averageBloodPressureSystolic: VitalsViewModel.shared.stressSummary?.bloodPressureSystolic,
            averageBloodPressureDiastolic: VitalsViewModel.shared.stressSummary?.bloodPressureDiastolic
        )

        let nutritionSummary = ProactiveTipRequestModel.NutritionSummary(
            averageBasalEnergyBurnedCalories: VitalsViewModel.shared.nutritionSummary?.details.basalEnergyBurned?.doubleValue(for: .largeCalorie()),
            averageActiveEnergyBurnedCalories: VitalsViewModel.shared.nutritionSummary?.details.activeEnergyBurned?.doubleValue(for: .largeCalorie()),
            averageDietaryEnergyConsumedCalories: VitalsViewModel.shared.nutritionSummary?.details.dietaryEnergy?.doubleValue(for: .largeCalorie()),
            averageProteinGrams: VitalsViewModel.shared.nutritionSummary?.details.averageProtein?.doubleValue(for: .gram()),
            averageCarbohydratesGrams: VitalsViewModel.shared.nutritionSummary?.details.averageCarbohydrates?.doubleValue(for: .gram()),
            averageFatGrams: VitalsViewModel.shared.nutritionSummary?.details.averageFat?.doubleValue(for: .gram()),
            averageSugarGrams: VitalsViewModel.shared.nutritionSummary?.details.averageSugar?.doubleValue(for: .gram()),
            averageVitaminAMicrograms: VitalsViewModel.shared.nutritionSummary?.details.averageVitaminA?.doubleValue(for: .gramUnit(with: .micro)),
            averageVitaminB6Milligrams: VitalsViewModel.shared.nutritionSummary?.details.averageVitaminB6?.doubleValue(for: .gramUnit(with: .milli)),
            averageVitaminB12Micrograms: VitalsViewModel.shared.nutritionSummary?.details.averageVitaminB12?.doubleValue(for: .gramUnit(with: .micro)),
            averageVitaminCMilligrams: VitalsViewModel.shared.nutritionSummary?.details.averageVitaminC?.doubleValue(for: .gramUnit(with: .milli)),
            averageVitaminDMicrograms: VitalsViewModel.shared.nutritionSummary?.details.averageVitaminD?.doubleValue(for: .gramUnit(with: .micro)),
            averageVitaminEMilligrams: VitalsViewModel.shared.nutritionSummary?.details.averageVitaminE?.doubleValue(for: .gramUnit(with: .milli))
        )

        let request = ProactiveTipRequestModel(
            stressMonthlySummary: stressSummary,
            nutritionMonthlySummary: nutritionSummary,
            bodyCompositionSummary: VitalsViewModel.shared.bodyFatPercentageSummary,
            cardioFitnessSummary: VitalsViewModel.shared.cardioFitnessSummary,
            sleepVitalsMonthlySummary: VitalsViewModel.shared.sleepVitalsSummary,
            activityLevelMonthlySummary: VitalsViewModel.shared.activityLevelSummary,
            chatHistory: chatHistory
        )

        guard let response = try? await NetworkRequester.shared.sendProactiveTip(request: request) else { return }

        await ChatViewModel.shared.appendAssistantMessage(message: response.message)
    }
}
