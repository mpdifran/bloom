//
//  JSONGenerator.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-12.
//

import SwiftUI
import HealthKit
import CoreHealth

final actor JSONGenerator {
  static let shared = JSONGenerator()

  private init() { }
}

extension JSONGenerator {

  func generateJSONString() async throws -> String {
    await VitalsCalculator.shared.forceFetchVitals()

    let calc = VitalsCalculator.shared

    let sleepAnalyses = await HealthStoreFetcher.shared.fetchSleepAnalysis(dateRange: .trailingMonthsFromNow(1))
    let sleepSummary = await HealthStoreFetcher.shared.fetchSleepVitalSummary(trailingMonthAnalyses: sleepAnalyses)

    let heartHealthDetails = await HealthStoreFetcher.shared.fetchHeartHealthDetails(dateRange: .trailingDaysFromNow(6))
    let heartDetails = SummaryJSON.HeartDetails(
      averageVo2Max: heartHealthDetails.averageVO2Max.map({ SummaryJSON.Quantity(value: $0.doubleValue(for: .vo2Max()), unit: .vo2Max()) }),
      averageHeartRateRecovery: heartHealthDetails.averageHeartRateRecovery.map({ SummaryJSON.Quantity(value: $0.doubleValue(for: .bpm()), unit: .bpm()) }),
      averageRestingHeartRate: heartHealthDetails.averageRestingHeartRate.map({ SummaryJSON.Quantity(value: $0.doubleValue(for: .bpm()), unit: .bpm()) })
    )

    let bodyCompSummary = await HealthStoreFetcher.shared.fetchBodyCompositionSummary()
    let bodyComp = SummaryJSON.BodyCompDetails(
      bodyFatPercentage: bodyCompSummary.details.bodyFatPercentage.map({ SummaryJSON.Quantity(value: $0.doubleValue(for: .percent()), unit: .percent()) }),
      bodyMass: bodyCompSummary.details.averageBodyMass.map({ SummaryJSON.Quantity(value: $0.doubleValue(for: .pound()), unit: .pound()) })
    )

    let stressSummary = await HealthStoreFetcher.shared.fetchStressMonthlySummary(trailingMonthAnalyses: sleepAnalyses)
    let stress = SummaryJSON.StressDetails(
      heartRateVariability: stressSummary?.details.heartRateVariability.map({
        SummaryJSON.DateQuantity(date: $0.date, quantity: SummaryJSON.Quantity(value: $0.quantity.doubleValue(for: .millisecond()), unit: .millisecond()))
      }) ?? [],
      bloodPressureSystolic: stressSummary?.details.bloodPressureSystolic.map({
        SummaryJSON.DateQuantity(date: $0.date, quantity: SummaryJSON.Quantity(value: $0.quantity.doubleValue(for: .millimeterOfMercury()), unit: .millimeterOfMercury()))
      }) ?? [],
      bloodPressureDiastolic: stressSummary?.details.bloodPressureDiastolic.map({
        SummaryJSON.DateQuantity(date: $0.date, quantity: SummaryJSON.Quantity(value: $0.quantity.doubleValue(for: .millimeterOfMercury()), unit: .millimeterOfMercury()))
      }) ?? []
    )

    let nutrition = await SummaryJSON.NutritionDetails(
      averageBasalEnergy: calc.nutritionSummary?.details.basalEnergyBurned.map({ SummaryJSON.Quantity(value: $0.doubleValue(for: .largeCalorie()), unit: .largeCalorie()) }),
      averageActiveEnergy: calc.nutritionSummary?.details.activeEnergyBurned.map({ SummaryJSON.Quantity(value: $0.doubleValue(for: .largeCalorie()), unit: .largeCalorie()) }),
      averageDietaryEnergy: calc.nutritionSummary?.details.dietaryEnergy.map({ SummaryJSON.Quantity(value: $0.doubleValue(for: .largeCalorie()), unit: .largeCalorie()) }),
      averageProtein: calc.nutritionSummary?.details.averageProtein.map({ SummaryJSON.Quantity(value: $0.doubleValue(for: .gram()), unit: .gram()) }),
      averageCarbohydrates: calc.nutritionSummary?.details.averageCarbohydrates.map({ SummaryJSON.Quantity(value: $0.doubleValue(for: .gram()), unit: .gram()) }),
      averagFat: calc.nutritionSummary?.details.averageFat.map({ SummaryJSON.Quantity(value: $0.doubleValue(for: .gram()), unit: .gram()) }),
      averageFiber: calc.nutritionSummary?.details.averageFiber.map({ SummaryJSON.Quantity(value: $0.doubleValue(for: .gram()), unit: .gram()) }),
      averageSugar: calc.nutritionSummary?.details.averageSugar.map({ SummaryJSON.Quantity(value: $0.doubleValue(for: .gram()), unit: .gram()) })
    )

    let bms = await calc.bowelMovementSummary?.bowelMovements.map({ SummaryJSON.BM(date: $0.date, bristolStoolType: $0.bristolStoolType, duration: $0.duration.name) }) ?? []

    let summary = await SummaryJSON(
      activityLevel: YouStatsCalculator.shared.activityLevelSummary?.details,
      sleep: sleepSummary.details,
      heartHealth: heartDetails,
      bodyComposition: bodyComp,
      stress: stress,
      nutrition: nutrition,
      bowelMovements: bms
    )

    let data = try JSONEncoder.main.encode(summary)

    return String(data: data, encoding: .utf8) ?? ""
  }
}

struct SummaryJSON: Codable {
  let activityLevel: ActivityLevelSummary.Details?
  let sleep: SleepVitalsMonthlySummary.Details?
  let heartHealth: HeartDetails
  let bodyComposition: BodyCompDetails
  let stress: StressDetails
  let nutrition: NutritionDetails
  let bowelMovements: [BM]
}

extension SummaryJSON {
  struct HeartDetails: Codable {
    let averageVo2Max: Quantity?
    let averageHeartRateRecovery: Quantity?
    let averageRestingHeartRate: Quantity?
  }

  struct BodyCompDetails: Codable {
    let bodyFatPercentage: Quantity?
    let bodyMass: Quantity?
  }

  struct StressDetails: Codable {
    let heartRateVariability: [DateQuantity]
    let bloodPressureSystolic: [DateQuantity]
    let bloodPressureDiastolic: [DateQuantity]
  }

  struct NutritionDetails: Codable {
    let averageBasalEnergy: Quantity?
    let averageActiveEnergy: Quantity?
    let averageDietaryEnergy: Quantity?
    let averageProtein: Quantity?
    let averageCarbohydrates: Quantity?
    let averagFat: Quantity?
    let averageFiber: Quantity?
    let averageSugar: Quantity?
  }
}

extension SummaryJSON {
  struct Quantity: Codable {
    let value: Double
    let unit: String

    init(value: Double, unit: HKUnit) {
      self.value = value
      self.unit = unit.unitString
    }
  }

  struct DateQuantity: Codable {
    let date: Date
    let quantity: Quantity
  }

  struct BM: Codable {
    let date: Date
    let bristolStoolType: Int
    let duration: String
  }
}
