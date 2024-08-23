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

private extension Double {
    static let hrvVariance: Double = 8
    static let rhrUpperThreadDiff: Double = 10
}

struct VitalStatusData: Identifiable, Hashable {
    var id: Int { hashValue }

    let name: String
    let value: String
    let mode: Mode
    let score: Double?
}

extension VitalStatusData {
    enum Mode: Int, Hashable {
        case insufficientData
        case threat
        case warning
        case good
        case excel
    }
}

extension VitalStatusData.Mode {

    var systemImage: String {
        switch self {
        case .insufficientData: "questionmark.diamond.fill"
        case .threat: "exclamationmark.octagon.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .good: "checkmark.circle.fill"
        case .excel: "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
        case .insufficientData: .gray
        case .threat: .pink
        case .warning: .yellow
        case .good: .green
        case .excel: .coreSleep
        }
    }
}

final class VitalsViewModel: ObservableObject {
    static let shared = VitalsViewModel()

    @Published var hrvStatus: VitalStatusData?
    @Published var sleepStatus: VitalStatusData?
    @Published var rhrStatus: VitalStatusData?

    @Published var vitals = [VitalModel]()

    @Published var activityLevelSummary: ActivityLevelSummary?
    @Published var sleepVitalsSummary: SleepVitalsMonthlySummary?
    @Published var cardioFitnessSummary: CardioFitnessMonthlySummary?
    @Published var bodyCompositionSummary: BodyCompositionMonthlySummary?
    @Published var stressSummary: StressMonthlySummary?
    @Published var nutritionSummary: NutritionMonthlySummary?
    @Published var exerciseEffectivenessSummary: ExerciseEffectivenessMonthlySummary?

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
}

private extension VitalsViewModel {

    func setupChangeObservers() {
        observerQueryHandles.removeAll(keepingCapacity: true)

        HealthManager.shared.healthStore.observeChanges(
            sampleTypes: [
                HKQuantityType(.vo2Max),
                HKQuantityType(.heartRateRecoveryOneMinute)
            ],
            dateRange: .trailingMonthsFromNow(2),
            frequency: .immediate
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
            dateRange: .trailingMonthsFromNow(2),
            frequency: .immediate
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
            dateRange: .trailingMonthsFromNow(2),
            frequency: .immediate
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
            dateRange: .trailingMonthsFromNow(2),
            frequency: .immediate
        ) {
            let summary = await HealthManager.shared.fetchStressMonthlySummary()
            await MainActor.run {
                self.stressSummary = summary
            }
        }
        .store(in: &observerQueryHandles)

        HealthManager.shared.healthStore.observeChanges(
            sampleTypes: HealthManager.shared.nutritionTypes,
            dateRange: .trailingMonthsFromNow(2),
            frequency: .immediate
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
            dateRange: .trailingMonthsFromNow(2),
            frequency: .immediate
        ) {
            Task {
                let summary = await HealthManager.shared.fetchExerciseEffectivenessSummary()
                await MainActor.run {
                    self.exerciseEffectivenessSummary = summary
                }
            }
        }
        .store(in: &observerQueryHandles)

        HealthManager.shared.observeSleepData()
    }

    func observeData() {
        setupChangeObservers()

        HealthManager.shared.$sleepAnalysis30Days
            .combineLatest(HealthManager.shared.$sleepAnalysisPrevious30Days)
            .receive(on: DispatchQueue(label: "VitalsViewModel.SleepSummary"))
            .map { (thisMonth, lastMonth) in
                guard let thisMonth, let lastMonth else { return nil }

                return SleepVitalsMonthlySummary(
                    averageREMSleepPercent: thisMonth.average(keyPath: \.remSleepPercent),
                    averageCoreSleepPercent: thisMonth.average(keyPath: \.coreSleepPercent),
                    averageDeepSleepPercent: thisMonth.average(keyPath: \.deepSleepPercent),
                    averageAwakeSleepPercent: thisMonth.average(keyPath: \.awakeSleepPercent),
                    averageSleepLength: thisMonth.average(keyPath: \.overallMinutes),
                    averageSleepScore: thisMonth.average(keyPath: \.overallScoreDouble),
                    lastMonthAverageSleepScore: lastMonth.average(keyPath: \.overallScoreDouble)
                )
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
    }

    func createVitals() {
        var vitals = [VitalModel]()
        if let sleepVitalsSummary {
            vitals.append(
                VitalModel(
                    id: .sleepQuality,
                    subtitle: sleepVitalsSummary.subtitleText,
                    status: sleepVitalsSummary.quality.name,
                    score: sleepVitalsSummary.score,
                    color: sleepVitalsSummary.quality.color,
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
                    status: activityLevelSummary.activityLevel.name,
                    score: activityLevelSummary.score,
                    color: activityLevelSummary.activityLevel.color,
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
                    status: bodyCompositionSummary.range.name,
                    score: bodyCompositionSummary.score,
                    color: bodyCompositionSummary.range.color,
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
                    subtitle: stressSummary.subtitle,
                    status: stressSummary.level.name,
                    score: stressSummary.score,
                    color: stressSummary.level.color,
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
                    status: nutritionSummary.status.title,
                    score: nutritionSummary.score,
                    color: nutritionSummary.status.color,
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

        vitals.sort(by: { $0.score < $1.score })

        DispatchQueue.main.async {
            self.vitals = vitals
        }
    }
}
