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

final class VitalsViewModel: ObservableObject {
    static let shared = VitalsViewModel()

    @Published var vitals = [VitalModel]()

    @Published var activityLevelSummary: ActivityLevelSummary?
    @Published var sleepVitalsSummary: SleepVitalsMonthlySummary?
    @Published var cardioFitnessSummary: CardioFitnessMonthlySummary?
    @Published var bodyCompositionSummary: BodyCompositionMonthlySummary?
    @Published var stressSummary: StressMonthlySummary?
    @Published var nutritionSummary: NutritionMonthlySummary?
    @Published var exerciseEffectivenessSummary: ExerciseEffectivenessMonthlySummary?
    @Published var bowelMovementSummary: BowelMovementMonthlySummary?
    @Published var menstrualSummary: MenstrualSummary?

    @Published var heartRateVariability = [DateQuantitySampleLegacy]()
    @Published var restingHeartRate = [DateQuantitySampleLegacy]()

    private var observerQueryHandles = [HKObserverQueryHandle]()
    private var cancellables = Set<AnyCancellable>()

    private let processingQueue = DispatchQueue(label: "VitalsViewModel.Processing")
    private let throttler = Throttler(timeInterval: 0.1, queue: DispatchQueue(label: "Throttler"))
    private let activityLevelThrottler = Throttler(timeInterval: 0.1, queue: DispatchQueue(label: "ActivityLevelThrottler"))

    private init() {
        observeData()
    }
}

extension VitalsViewModel {

    func refreshVitals() async {
        setupChangeObservers()
    }

    func fetchSwiftDataTypes() {
        Task {
            let summary = await DataFetcher.shared.fetchBowelMovementMonthlySummary()
            await MainActor.run {
                self.bowelMovementSummary = summary
            }
        }
    }
}

private extension VitalsViewModel {

    func setupChangeObservers() {
        observerQueryHandles.removeAll(keepingCapacity: true)

        HealthManager.shared.healthStore.observeChanges(
            sampleTypes: [
                HKQuantityType(.vo2Max),
                HKQuantityType(.heartRateRecoveryOneMinute)
            ],
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: .now) ?? .now
        ) {
            let summary = await HealthManager.shared.fetchCardioFitnessSummary()
            await MainActor.run {
                self.cardioFitnessSummary = summary
            }
        }
        .store(in: &observerQueryHandles)

        HealthManager.shared.healthStore.observeChanges(
            sampleTypes: [
                HKQuantityType(.basalEnergyBurned),
                HKQuantityType(.activeEnergyBurned)
            ],
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: .now) ?? .now
        ) { [activityLevelThrottler, processingQueue] in
            processingQueue.async {
                activityLevelThrottler.perform {
                    Task {
                        let summary = await HealthManager.shared.fetchActivityLevelSummary()
                        await MainActor.run {
                            self.activityLevelSummary = summary
                        }
                    }
                }
            }
        }
        .store(in: &observerQueryHandles)

        HealthManager.shared.healthStore.observeChanges(
            sampleType: HKQuantityType(.bodyFatPercentage),
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: .now) ?? .now
        ) {
            let summary = await HealthManager.shared.fetchBodyCompositionSummary()
            await MainActor.run {
                self.bodyCompositionSummary = summary
            }
        }
        .store(in: &observerQueryHandles)

        HealthManager.shared.healthStore.observeChanges(
            sampleTypes: [
                HKQuantityType(.heartRateVariabilitySDNN),
                HKQuantityType(.restingHeartRate),
                HKQuantityType(.bloodPressureSystolic),
                HKQuantityType(.bloodPressureDiastolic)
            ],
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: .now) ?? .now
        ) {
            let summary = await HealthManager.shared.fetchStressMonthlySummary()
            await MainActor.run {
                self.stressSummary = summary
            }
        }
        .store(in: &observerQueryHandles)

        HealthManager.shared.healthStore.observeChanges(
            sampleTypes: HealthManager.shared.nutritionTypes,
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: .now) ?? .now
        ) { [throttler, processingQueue] in
            processingQueue.async {
                throttler.perform {
                    Task {
                        let summary = await HealthManager.shared.fetchNutritionMonthlySummary()
                        await MainActor.run {
                            self.nutritionSummary = summary
                        }
                    }
                }
            }
        }
        .store(in: &observerQueryHandles)

        HealthManager.shared.healthStore.observeChanges(
            sampleType: HKWorkoutType.workoutType(),
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: .now) ?? .now
        ) {
            let summary = await HealthManager.shared.fetchExerciseEffectivenessSummary()
            await MainActor.run {
                self.exerciseEffectivenessSummary = summary
            }
        }
        .store(in: &observerQueryHandles)

        HealthManager.shared.healthStore.observeChanges(
            sampleType: HKCategoryType(.menstrualFlow),
            startDate: Calendar.current.date(byAdding: .month, value: -7, to: .now) ?? .now
        ) {
            let summary = await HealthManager.shared.fetchMenstrualSummary()
            await MainActor.run {
                self.menstrualSummary = summary
            }
        }
        .store(in: &observerQueryHandles)

        HealthManager.shared.observeSleepData()

        fetchSwiftDataTypes()
    }

    func observeData() {
        setupChangeObservers()

        HealthManager.shared.$sleepAnalysis30Days
            .combineLatest(HealthManager.shared.$sleepAnalysisPrevious30Days)
            .receive(on: DispatchQueue(label: "VitalsViewModel.SleepSummary"))
            .map { (_, _) in

                return HealthManager.shared.fetchSleepVitalSummary()
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$sleepVitalsSummary)

        $activityLevelSummary
            .receive(on: processingQueue)
            .sink { [weak self] (_) in
                self?.createVitals()
            }
            .store(in: &cancellables)
        $sleepVitalsSummary
            .receive(on: processingQueue)
            .sink { [weak self] (_) in
                self?.createVitals()
            }
            .store(in: &cancellables)
        $cardioFitnessSummary
            .receive(on: processingQueue)
            .sink { [weak self] (_) in
                self?.createVitals()
            }
            .store(in: &cancellables)
        $bodyCompositionSummary
            .receive(on: processingQueue)
            .sink { [weak self] (_) in
                self?.createVitals()
            }
            .store(in: &cancellables)
        $stressSummary
            .receive(on: processingQueue)
            .sink { [weak self] (_) in
                self?.createVitals()
            }
            .store(in: &cancellables)
        $nutritionSummary
            .receive(on: processingQueue)
            .sink { [weak self] (_) in
                self?.createVitals()
            }
            .store(in: &cancellables)
        $exerciseEffectivenessSummary
            .receive(on: processingQueue)
            .sink { [weak self] (_) in
                self?.createVitals()
            }
            .store(in: &cancellables)
        $menstrualSummary
            .receive(on: processingQueue)
            .sink { [weak self] (_) in
                self?.createVitals()
            }
            .store(in: &cancellables)
        $bowelMovementSummary
            .receive(on: processingQueue)
            .sink { [weak self] (_) in
                self?.createVitals()
            }
            .store(in: &cancellables)
    }

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
                    trend: sleepVitalsSummary.trend
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
                    trend: activityLevelSummary.trend
                )
            )
        } else {
            vitals.append(.init(id: .activityLevel))
        }
        if let cardioFitnessSummary {
            vitals.append(
                VitalModel(
                    id: .cardioFitness,
                    subtitle: cardioFitnessSummary.subtitle,
                    status: cardioFitnessSummary.level.name,
                    score: cardioFitnessSummary.score,
                    color: cardioFitnessSummary.level.color,
                    trend: cardioFitnessSummary.trend
                )
            )
        } else {
            vitals.append(.init(id: .cardioFitness))
        }
        if let bodyCompositionSummary {
            vitals.append(
                VitalModel(
                    id: .bodyComposition,
                    subtitle: bodyCompositionSummary.subtitle,
                    status: bodyCompositionSummary.details.range?.name,
                    score: bodyCompositionSummary.score,
                    color: bodyCompositionSummary.details.range?.color,
                    trend: bodyCompositionSummary.trend
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
                    trend: stressSummary.trend
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
                    trend: nutritionSummary.trend
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
                    trend: exerciseEffectivenessSummary.trend
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
                        status: menstrualSummary.phaseDescription,
                        score: 1,
                        color: .green,
                        trend: .noTrend
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
                    subtitle: bowelMovementSummary.details?.subtitle,
                    status: bowelMovementSummary.details?.rating.name,
                    score: bowelMovementSummary.details?.score ?? 1,
                    color: bowelMovementSummary.details?.rating.color,
                    trend: bowelMovementSummary.trend
                )
            )
        } else {
            vitals.append(.init(id: .bowelMovements))
        }

        vitals.sort(by: { $0.score < $1.score })

        DispatchQueue.main.async {
            self.vitals = vitals
        }
    }
}
