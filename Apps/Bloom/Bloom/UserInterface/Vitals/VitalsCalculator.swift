//
//  VitalsCalculator.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-10.
//

import Foundation
import DataContainer

final actor VitalsCalculator {
  static let shared = VitalsCalculator()

  @AsyncStreamable var vitals = [VitalModel]()

  @AsyncStreamable var activityLevelSummary: ActivityLevelSummary?
  @AsyncStreamable var sleepVitalsSummary: SleepVitalsMonthlySummary?
  @AsyncStreamable var heartHealthSummary: HeartHealthMonthlySummary?
  @AsyncStreamable var bodyCompositionSummary: BodyCompositionMonthlySummary?
  @AsyncStreamable var stressSummary: StressMonthlySummary?
  @AsyncStreamable var nutritionSummary: NutritionMonthlySummary?
  @AsyncStreamable var exerciseEffectivenessSummary: ExerciseEffectivenessMonthlySummary?
  @AsyncStreamable var bowelMovementSummary: BowelMovementMonthlySummary?
  @AsyncStreamable var menstrualSummary: MenstrualSummary?

  private init() {
    if let date = UserDefaults.group.object(forKey: "VitalsCalculator.lastVitalFetchDate") as? Date {
      lastVitalFetchDate = date
    }
  }

  private var lastVitalFetchDate: Date? {
    didSet {
      UserDefaults.group.set(lastVitalFetchDate, forKey: "VitalsCalculator.lastVitalFetchDate")
    }
  }
}

extension VitalsCalculator {

  func refreshVitals() async {
    if vitals.isNotEmpty {
      if let lastVitalFetchDate {
        let minutes = Calendar.current.dateComponents([.minute], from: lastVitalFetchDate, to: .now).minute ?? 0

        if minutes < 3 {
          print("Returning early since we, like, just fetched vitals.")
          return
        }
      }
    }

    await forceFetchVitals()
  }

  func forceFetchVitals() async {
    let sleepAnalyses = await HealthStoreFetcher.shared.fetchSleepAnalysis(dateRange: .trailingMonthsFromNow(1))

    heartHealthSummary = await HealthStoreFetcher.shared.fetchHeartHealthSummary()
    activityLevelSummary = await HealthStoreFetcher.shared.fetchActivityLevelSummary()
    bodyCompositionSummary = await HealthStoreFetcher.shared.fetchBodyCompositionSummary()
    sleepVitalsSummary = await HealthStoreFetcher.shared.fetchSleepVitalSummary(trailingMonthAnalyses: sleepAnalyses)
    stressSummary = await HealthStoreFetcher.shared.fetchStressMonthlySummary(trailingMonthAnalyses: sleepAnalyses)
    nutritionSummary = await HealthStoreFetcher.shared.fetchNutritionMonthlySummary()
    exerciseEffectivenessSummary = await HealthStoreFetcher.shared.fetchExerciseEffectivenessSummary()
    menstrualSummary = await HealthStoreFetcher.shared.fetchMenstrualSummary()
    bowelMovementSummary = await fetchBowelMovementMonthlySummary()

    await createVitals()
  }

  func forceFectchMenstrualSummary() async {
    menstrualSummary = await HealthStoreFetcher.shared.fetchMenstrualSummary()

    await createVitals()
  }

  func fetchSwiftDataTypes() async {
    self.bowelMovementSummary = await fetchBowelMovementMonthlySummary()

    await createVitals()
  }

  func recalculateVitals() async {
    await createVitals()
  }
}

private extension VitalsCalculator {

  func fetchBowelMovementMonthlySummary() async -> BowelMovementMonthlySummary? {
    let modelActor = BowelMovementModelActor.standard()
    let samples = (try? await modelActor.fetchBowelMovements(dateRange: .trailingMonthsFromNow(1))) ?? []
    return BowelMovementMonthlySummary(bowelMovements: samples)
  }
}

private extension VitalsCalculator {

  func createVitals() async {
    var vitals = [VitalModel]()
    if let sleepVitalsSummary {
      vitals.append(
        VitalModel(
          id: .sleepQuality,
          subtitle: sleepVitalsSummary.subtitleText,
          status: sleepVitalsSummary.details.quality?.name,
          color: sleepVitalsSummary.details.quality?.color,
          barLevel: sleepVitalsSummary.barLevel,
          hasNoData: sleepVitalsSummary.details.hasNoData
        )
      )
    } else {
      vitals.append(.init(id: .sleepQuality))
    }
    if let activityLevelSummary {
      vitals.append(
        VitalModel(
          id: .activityLevel,
          subtitle: activityLevelSummary.subtitle,
          status: activityLevelSummary.details.activityLevel?.name,
          color: activityLevelSummary.details.activityLevel?.color,
          barLevel: activityLevelSummary.barLevel,
          hasNoData: activityLevelSummary.details.hasNoData
        )
      )
    } else {
      vitals.append(.init(id: .activityLevel))
    }
    if let heartHealthSummary {
      await vitals.append(
        VitalModel(
          id: .heartHealth,
          subtitle: heartHealthSummary.details.subtitle,
          status: heartHealthSummary.details.level?.name,
          color: heartHealthSummary.details.level?.color,
          barLevel: heartHealthSummary.details.barLevel,
          hasNoData: heartHealthSummary.details.hasNoData
        )
      )
    } else {
      vitals.append(.init(id: .heartHealth))
    }
    if let bodyCompositionSummary {
      await vitals.append(
        VitalModel(
          id: .bodyComposition,
          subtitle: bodyCompositionSummary.subtitle,
          status: bodyCompositionSummary.details.range?.name,
          color: bodyCompositionSummary.details.range?.color,
          barLevel: bodyCompositionSummary.barLevel,
          hasNoData: bodyCompositionSummary.details.hasNoData
        )
      )
    } else {
      vitals.append(.init(id: .bodyComposition))
    }
    if let stressSummary {
      vitals.append(
        VitalModel(
          id: .stressLevels,
          subtitle: stressSummary.details.subtitle,
          status: stressSummary.details.level?.name,
          color: stressSummary.details.level?.color,
          barLevel: stressSummary.barLevel,
          hasNoData: stressSummary.hasNoData
        )
      )
    } else {
      vitals.append(.init(id: .stressLevels))
    }
    if let nutritionSummary {
      vitals.append(
        VitalModel(
          id: .nutrition,
          subtitle: nutritionSummary.subtitle,
          status: await nutritionSummary.status()?.title,
          color: await nutritionSummary.status()?.color,
          barLevel: await nutritionSummary.barLevel(),
          hasNoData: await nutritionSummary.hasNoData()
        )
      )
    } else {
      vitals.append(.init(id: .nutrition))
    }
    if let exerciseEffectivenessSummary {
      vitals.append(
        VitalModel(
          id: .exerciseEffectiveness,
          subtitle: exerciseEffectivenessSummary.details.subtitle,
          status: exerciseEffectivenessSummary.details.level.name,
          color: exerciseEffectivenessSummary.details.level.color,
          barLevel: exerciseEffectivenessSummary.barLevel,
          hasNoData: exerciseEffectivenessSummary.details.hasNoData
        )
      )
    } else {
      vitals.append(.init(id: .exerciseEffectiveness))
    }
    if await HealthManager.shared.sex() == .female {
      if let menstrualSummary {
        vitals.append(
          VitalModel(
            id: .cycleTracking,
            subtitle: menstrualSummary.subtitle,
            status: menstrualSummary.phaseName,
            color: menstrualSummary.color,
            barLevel: nil,
            hasNoData: menstrualSummary.hasNoData
          )
        )
      } else {
        vitals.append(.init(id: .cycleTracking))
      }
    }
    if let bowelMovementSummary {
      vitals.append(
        VitalModel(
          id: .bowelMovements,
          subtitle: bowelMovementSummary.subtitle,
          status: bowelMovementSummary.rating?.name,
          color: bowelMovementSummary.rating?.color,
          barLevel: bowelMovementSummary.barLevel,
          hasNoData: bowelMovementSummary.hasNoData
        )
      )
    } else {
      vitals.append(.init(id: .bowelMovements))
    }

    vitals.sort(by: { lhs, rhs in
      guard let lhsLevel = lhs.barLevel else { return false }
      guard let rhsLevel = rhs.barLevel else { return true }

      return lhsLevel < rhsLevel
    })

    self.vitals = vitals
  }
}
