//
//  VitalsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-22.
//

import SwiftUI
import HealthKit
import Combine
import AppFoundations
import DataContainer
import SwiftData

final class VitalsViewModel: ObservableObject {
    static let shared = VitalsViewModel()

    @Published var vitals = [VitalModel]()

    @Published var activityLevelSummary: ActivityLevelSummary?
    @Published var sleepVitalsSummary: SleepVitalsMonthlySummary?
    @Published var heartHealthSummary: HeartHealthMonthlySummary?
    @Published var bodyCompositionSummary: BodyCompositionMonthlySummary?
    @Published var stressSummary: StressMonthlySummary?
    @Published var nutritionSummary: NutritionMonthlySummary?
    @Published var exerciseEffectivenessSummary: ExerciseEffectivenessMonthlySummary?
    @Published var bowelMovementSummary: BowelMovementMonthlySummary?
    @Published var menstrualSummary: MenstrualSummary?

    @Published var heartRateVariability = [DateQuantitySampleLegacy]()
    @Published var restingHeartRate = [DateQuantitySampleLegacy]()

    private var lastVitalFetchDate: Date? {
        didSet {
            UserDefaults.group.set(lastVitalFetchDate, forKey: "VitalsViewModel.lastVitalFetchDate")
        }
    }

    private var observerQueryHandles = [HKObserverQueryHandle]()
    private var cancellables = Set<AnyCancellable>()

    private let processingQueue = DispatchQueue(label: "VitalsViewModel.Processing")
    private let throttler = Throttler(timeInterval: 0.1, queue: DispatchQueue(label: "Throttler"))
    private let activityLevelThrottler = Throttler(timeInterval: 0.1, queue: DispatchQueue(label: "ActivityLevelThrottler"))
    private let stressThrottler = Throttler(timeInterval: 2, queue: DispatchQueue(label: "StressThrottler"))

    private let modelContext = ModelContext(ContainerHolder.shared.container)

    init() {
        if let date = UserDefaults.group.object(forKey: "VitalsViewModel.lastVitalFetchDate") as? Date {
            lastVitalFetchDate = date
        }
    }
}

extension VitalsViewModel {

    func refreshVitals() async {
        if vitals.isNotEmpty {
            if let lastVitalFetchDate {
                let minutes = Calendar.current.dateComponents([.minute], from: lastVitalFetchDate, to: .now).minute ?? 0
                
                if minutes < 3 {
                    print("Returning early since we like just fetched vitals.")
                    return
                }
            }
        }

        await forceFetchVitals()
    }

    func fetchSwiftDataTypes() {
        Task {
            let summary = modelContext.fetchBowelMovementMonthlySummary()
            await MainActor.run {
                self.bowelMovementSummary = summary
            }
        }
    }

    func forceFetchVitals() async {
        let sleepAnalyses = await HealthManager.shared.fetchSleepAnalysis(dateRange: .trailingMonthsFromNow(1))

        let cardio = await HealthManager.shared.fetchHeartHealthSummary()
        let activityLevel = await HealthManager.shared.fetchActivityLevelSummary()
        let bodyComposition = await HealthManager.shared.fetchBodyCompositionSummary()
        let sleep = await HealthManager.shared.fetchSleepVitalSummary(trailingMonthAnalyses: sleepAnalyses)
        let stress = await HealthManager.shared.fetchStressMonthlySummary(trailingMonthAnalyses: sleepAnalyses)
        let nutrition = await HealthManager.shared.fetchNutritionMonthlySummary()
        let exerciseEffectiveness = await HealthManager.shared.fetchExerciseEffectivenessSummary()
        let menstrual = await HealthManager.shared.fetchMenstrualSummary()
        let bowelMovements = modelContext.fetchBowelMovementMonthlySummary()

        await MainActor.run {
            self.heartHealthSummary = cardio
            self.activityLevelSummary = activityLevel
            self.bodyCompositionSummary = bodyComposition
            self.stressSummary = stress
            self.nutritionSummary = nutrition
            self.exerciseEffectivenessSummary = exerciseEffectiveness
            self.sleepVitalsSummary = sleep
            self.menstrualSummary = menstrual
            self.bowelMovementSummary = bowelMovements

            self.createVitals()

            self.lastVitalFetchDate = .now
        }
    }
}

private extension VitalsViewModel {

    func createVitals() {
        var vitals = [VitalModel]()
        if let sleepVitalsSummary {
            vitals.append(
                VitalModel(
                    id: .sleepQuality,
                    subtitle: sleepVitalsSummary.subtitleText,
                    status: sleepVitalsSummary.details.quality?.name,
                    score: sleepVitalsSummary.score,
                    color: sleepVitalsSummary.details.quality?.color,
                    barLevel: sleepVitalsSummary.barLevel
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
                    score: activityLevelSummary.details.score,
                    color: activityLevelSummary.details.activityLevel?.color,
                    barLevel: activityLevelSummary.barLevel
                )
            )
        } else {
            vitals.append(.init(id: .activityLevel))
        }
        if let heartHealthSummary {
            vitals.append(
                VitalModel(
                    id: .heartHealth,
                    subtitle: heartHealthSummary.details.subtitle,
                    status: heartHealthSummary.details.level?.name,
                    score: heartHealthSummary.details.score ?? 1,
                    color: heartHealthSummary.details.level?.color,
                    barLevel: heartHealthSummary.details.barLevel
                )
            )
        } else {
            vitals.append(.init(id: .heartHealth))
        }
        if let bodyCompositionSummary {
            vitals.append(
                VitalModel(
                    id: .bodyComposition,
                    subtitle: bodyCompositionSummary.subtitle,
                    status: bodyCompositionSummary.details.range?.name,
                    score: bodyCompositionSummary.score,
                    color: bodyCompositionSummary.details.range?.color,
                    barLevel: bodyCompositionSummary.barLevel
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
                    score: stressSummary.score,
                    color: stressSummary.details.level?.color,
                    barLevel: stressSummary.barLevel
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
                    status: nutritionSummary.status?.title,
                    score: nutritionSummary.score,
                    color: nutritionSummary.status?.color,
                    barLevel: nutritionSummary.barLevel
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
                    score: exerciseEffectivenessSummary.details.score,
                    color: exerciseEffectivenessSummary.details.level.color,
                    barLevel: exerciseEffectivenessSummary.barLevel
                )
            )
        } else {
            vitals.append(.init(id: .exerciseEffectiveness))
        }
        if HealthManager.shared.sex() == .female {
            if let menstrualSummary {
                vitals.append(
                    VitalModel(
                        id: .cycleTracking,
                        subtitle: menstrualSummary.subtitle,
                        status: menstrualSummary.phaseName,
                        score: 1,
                        color: menstrualSummary.color,
                        barLevel: nil
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
                    status: bowelMovementSummary.rating.name,
                    score: bowelMovementSummary.score,
                    color: bowelMovementSummary.rating.color,
                    barLevel: bowelMovementSummary.barLevel
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

        DispatchQueue.main.async {
            self.vitals = vitals
        }
    }
}
