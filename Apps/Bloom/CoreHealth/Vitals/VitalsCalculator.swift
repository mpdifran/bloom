//
//  VitalsCalculator.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-10.
//

import Foundation
import DataContainer
import BloomFoundation
import HealthKit

public final actor VitalsCalculator {
  public static let shared = VitalsCalculator()

  @AsyncStreamable public var vitals = [VitalModel]()

  @AsyncStreamable public var sleepVitalsSummary: SleepVitalsMonthlySummary?
  @AsyncStreamable public var heartHealthSummary: HeartHealthMonthlySummary?
  @AsyncStreamable public var bodyCompositionSummary: BodyCompositionMonthlySummary?
  @AsyncStreamable public var stressSummary: StressMonthlySummary?
  @AsyncStreamable public var nutritionSummary: NutritionMonthlySummary?
  @AsyncStreamable public var bowelMovementSummary: BowelMovementSummary?
  @AsyncStreamable public var menstrualSummary: MenstrualSummary?
  @AsyncStreamable public var alcoholSummary: AlcoholSummary?

  private var alcoholObserverHandle: HKObserverQueryHandle?

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

public extension VitalsCalculator {

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
    bodyCompositionSummary = await HealthStoreFetcher.shared.fetchBodyCompositionSummary()
    sleepVitalsSummary = await HealthStoreFetcher.shared.fetchSleepVitalSummary(trailingMonthAnalyses: sleepAnalyses)
    stressSummary = await HealthStoreFetcher.shared.fetchStressMonthlySummary(trailingMonthAnalyses: sleepAnalyses)
    nutritionSummary = await HealthStoreFetcher.shared.fetchNutritionMonthlySummary()
    menstrualSummary = await HealthStoreFetcher.shared.fetchMenstrualSummary()
    bowelMovementSummary = await fetchBowelMovementSummary()
    alcoholSummary = await HealthStoreFetcher.shared.fetchAlcoholSummary(
      sex: HealthDefaults.shared.getSexKind()
    )
    startObservingAlcoholChanges()

    await createVitals()
  }

  func forceFectchMenstrualSummary() async {
    menstrualSummary = await HealthStoreFetcher.shared.fetchMenstrualSummary()

    await createVitals()
  }

  func fetchSwiftDataTypes() async {
    self.bowelMovementSummary = await fetchBowelMovementSummary()

    await createVitals()
  }

  func recalculateVitals() async {
    await createVitals()
  }

  func startObservingAlcoholChanges() {
    alcoholObserverHandle = HealthManager.shared.healthStore.observeChanges(
      sampleType: HKQuantityType(.numberOfAlcoholicBeverages),
      startDate: Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
    ) {
      let summary = await HealthStoreFetcher.shared.fetchAlcoholSummary(
        sex: HealthDefaults.shared.getSexKind()
      )
      await self.setAlcoholSummary(summary)
    }
  }

  func setAlcoholSummary(_ summary: AlcoholSummary?) {
    self.alcoholSummary = summary
  }
}

private extension VitalsCalculator {

  func fetchBowelMovementSummary() async -> BowelMovementSummary? {
    let modelActor = BowelMovementModelActor.standard()
    let samples = (try? await modelActor.fetchBowelMovements(dateRange: .trailingDaysFromNow(7))) ?? []
    return BowelMovementSummary(bowelMovements: samples)
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
      vitals.append(VitalModel(id: .sleepQuality))
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
      vitals.append(VitalModel(id: .heartHealth))
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
      vitals.append(VitalModel(id: .bodyComposition))
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
      vitals.append(VitalModel(id: .stressLevels))
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
      vitals.append(VitalModel(id: .nutrition))
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
        vitals.append(VitalModel(id: .cycleTracking))
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
      vitals.append(VitalModel(id: .bowelMovements))
    }

    vitals.sort(by: { lhs, rhs in
      guard let lhsLevel = lhs.barLevel else { return false }
      guard let rhsLevel = rhs.barLevel else { return true }

      return lhsLevel < rhsLevel
    })

    self.vitals = vitals
  }
}
