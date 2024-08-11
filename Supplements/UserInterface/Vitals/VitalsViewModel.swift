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
    @Published var bodyFatPercentageSummary: BodyCompositionMonthlySummary?
    @Published var mobilitySummary: MobilityMonthlySummary?
    @Published var stressSummary: StressMonthlySummary?
    @Published var nutritionSummary: NutritionMonthlySummary?

    @Published var heartRateVariability = [DateQuantitySample]()
    @Published var restingHeartRate = [DateQuantitySample]()

    private var cancellables = Set<AnyCancellable>()

    private let processingQueue = DispatchQueue(label: "VitalsViewModel.Processing")
    private let throttler = Throttler(timeInterval: 0.1, queue: DispatchQueue(label: "Throttler"))
    private let activityLevelThrottler = Throttler(timeInterval: 0.1, queue: DispatchQueue(label: "ActivityLevelThrottler"))

    private init() {
        observeData()
    }
}

private extension VitalsViewModel {

    func observeData() {
//        do {
//            try HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.heartRateVariabilitySDNN)) {
//                let heartRateVariability = await HealthManager.shared.fetchHeartRateVariability(periodDays: 28)
//                await MainActor.run {
//                    self.heartRateVariability = heartRateVariability
//                }
//            }
//        } catch {
//            print(error)
//        }
//        do {
//            try HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.restingHeartRate)) {
//                let restingHeartRate = await HealthManager.shared.fetchRestingHeartRate(period: 28)
//                await MainActor.run {
//                    self.restingHeartRate = restingHeartRate
//                }
//            }
//        } catch {
//            print(error)
//        }
//
//        HealthManager.shared.$sleepAnalysis7Days
//            .combineLatest($heartRateVariability, $restingHeartRate)
//            .sink(receiveValue: { [weak self] (sleepAnalysis, heartRateVariability, restingHeartRate) in
//                self?.createVitalStatuses(
//                    sleepAnalysis: sleepAnalysis ?? [],
//                    heartRateVariability: heartRateVariability,
//                    restingHeartRate: restingHeartRate
//                )
//            })
//            .store(in: &cancellables)

        do {
            try HealthManager.shared.healthStore.observeChanges(
                sampleTypes: [
                    HKQuantityType(.basalEnergyBurned),
                    HKQuantityType(.activeEnergyBurned)
                ]
            ) { [activityLevelThrottler] in
                activityLevelThrottler.perform {
                    Task {
                        let summary = await HealthManager.shared.fetchActivityLevelSummary()
                        await MainActor.run {
                            self.activityLevelSummary = summary
                        }
                    }
                }
            }
        } catch {
            print(error)
        }

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

        do {
            try HealthManager.shared.healthStore.observeChanges(
                sampleTypes: [
                    HKQuantityType(.vo2Max),
                    HKQuantityType(.heartRateRecoveryOneMinute)
                ]
            ) {
                let thisMonth = await HealthManager.shared.fetchVO2Max()
                let hrr = await HealthManager.shared.fetchHeartRateRecovery()
                let lastMonth = await HealthManager.shared.fetchVO2Max(numPastMonths: 1)
                let hrrLastMonth = await HealthManager.shared.fetchHeartRateRecovery(numPastMonths: 1)
                await MainActor.run {
                    self.cardioFitnessSummary = CardioFitnessMonthlySummary(
                        averageVO2Max: thisMonth?.0,
                        averageHeartRateRecovery: hrr?.0,
                        lastMonthAverageVO2Max: lastMonth?.0,
                        lastMonthAverageHeartRateRecovery: hrrLastMonth?.0
                    )
                }
            }
        } catch {
            print(error)
        }

        do {
            try HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.bodyFatPercentage)) {
                let thisMonth = await HealthManager.shared.fetchAverageBodyFatPercentage()
                let lastMonth = await HealthManager.shared.fetchAverageBodyFatPercentage(numPastMonths: 1)
                await MainActor.run {
                    self.bodyFatPercentageSummary = BodyCompositionMonthlySummary(
                        bodyFatPercentage: thisMonth?.0,
                        lastMonthBodyFatPercentage: lastMonth?.0
                    )
                }
            }
        } catch {
            print(error)
        }

//        do {
//            try HealthManager.shared.healthStore.observeChanges(
//                sampleTypes: [
//                    HKCategoryType(.appleWalkingSteadinessEvent),
//                    HKQuantityType(.sixMinuteWalkTestDistance),
//                    HKQuantityType(.walkingDoubleSupportPercentage)
//                ]
//            ) {
//                let summary = await HealthManager.shared.fetchMonthlyMobilitySummary()
//                await MainActor.run {
//                    self.mobilitySummary = summary
//                }
//            }
//        } catch {
//            print(error)
//        }

        do {
            try HealthManager.shared.healthStore.observeChanges(
                sampleTypes: [
                    HKQuantityType(.heartRateVariabilitySDNN),
                    HKQuantityType(.restingHeartRate),
                    HKCategoryType(.sleepAnalysis),
                    HKQuantityType(.bloodPressureSystolic),
                    HKQuantityType(.bloodPressureDiastolic)
                ]
            ) {
                let summary = await HealthManager.shared.fetchStressMonthlySummary()
                await MainActor.run {
                    self.stressSummary = summary
                }
            }
        } catch {
            print(error)
        }

        do {
            try HealthManager.shared.healthStore.observeChanges(sampleTypes: HealthManager.shared.nutritionTypes) { [throttler] in
                throttler.perform {
                    Task {
                        let summary = await HealthManager.shared.fetchNutritionMonthlySummary()
                        await MainActor.run {
                            self.nutritionSummary = summary
                        }
                    }
                }
            }
        } catch {
            print(error)
        }

        HealthManager.shared.$sleepAnalysis30Days
            .sink { (_) in
                Task {
                    let summary = await HealthManager.shared.fetchStressMonthlySummary()
                    await MainActor.run {
                        self.stressSummary = summary
                    }
                }
            }
            .store(in: &cancellables)

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
        $bodyFatPercentageSummary
            .receive(on: processingQueue)
            .sink { [weak self] (_) in
                self?.createVitals()
            }
            .store(in: &cancellables)
        $mobilitySummary
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
        }
        if let bodyFatPercentageSummary {
            vitals.append(
                VitalModel(
                    id: .bodyComposition,
                    subtitle: bodyFatPercentageSummary.subtitle,
                    status: bodyFatPercentageSummary.range.name,
                    score: bodyFatPercentageSummary.score,
                    color: bodyFatPercentageSummary.range.color,
                    trend: bodyFatPercentageSummary.trend
                )
            )
        }
        if let mobilitySummary {
            vitals.append(
                VitalModel(
                    id: .mobility,
                    subtitle: mobilitySummary.subtitle,
                    status: mobilitySummary.status.name,
                    score: mobilitySummary.score,
                    color: mobilitySummary.status.color,
                    trend: mobilitySummary.trend
                )
            )
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
        }

        vitals.sort(by: { $0.score < $1.score })

        DispatchQueue.main.async {
            self.vitals = vitals
        }
    }

    func createVitalStatuses(
        sleepAnalysis: [SleepAnalysis],
        heartRateVariability: [DateQuantitySample],
        restingHeartRate: [DateQuantitySample]
    ) {
        if let firstHRV = heartRateVariability.first {
            let average = heartRateVariability.average(keyPath: \.quantity)

            let mode: VitalStatusData.Mode
            if firstHRV.quantity >= average + .hrvVariance {
                mode = .excel
            } else if firstHRV.quantity < average + .hrvVariance && firstHRV.quantity >= average - .hrvVariance {
                mode = .good
            } else if firstHRV.quantity < average - .hrvVariance && firstHRV.quantity >= average - (.hrvVariance * 2) {
                mode = .warning
            } else {
                mode = .threat
            }

            let lower = average - (.hrvVariance * 2)
            let upper = average + .hrvVariance

            hrvStatus = VitalStatusData(
                name: "Heart Rate Variability",
                value: "\(String(format: "%.0f", firstHRV.quantity)) ms",
                mode: mode,
                score: firstHRV.quantity.scaledPercent(lower: lower, upper: upper)
            )

        } else {
            hrvStatus = VitalStatusData(
                name: "Heart Rate Variability",
                value: "No Data",
                mode: .insufficientData,
                score: nil
            )
        }

        if let lastSleepAnalysis = sleepAnalysis.last {
            let mode = lastSleepAnalysis.sleepQuality
            let value: String
            switch mode {
            case .insufficientData: value = "No Data"
            case .threat: value = "Poor"
            case .warning: value = "Low"
            case .good: value = "Good"
            case .excel: value = "Great"
            }
            sleepStatus = VitalStatusData(
                name: "Sleep Quality",
                value: value,
                mode: mode,
                score: lastSleepAnalysis.overallScoreDouble / 10
            )
        } else {
            sleepStatus = VitalStatusData(
                name: "Sleep Quality",
                value: "No Data",
                mode: .insufficientData,
                score: nil
            )
        }

        if let firstRHR = restingHeartRate.first {
            let (min, max) = HealthManager.shared.goalRestingHeartRateForUser()

            let mode: VitalStatusData.Mode
            if firstRHR.quantity < min {
                mode = .excel
            } else if firstRHR.quantity >= min && firstRHR.quantity <= max {
                mode = .good
            } else if firstRHR.quantity > max && firstRHR.quantity <= max + .rhrUpperThreadDiff {
                mode = .warning
            } else {
                mode = .threat
            }

            rhrStatus = VitalStatusData(
                name: "Resting Heart Rate",
                value: "\(String(format: "%.0f", firstRHR.quantity)) bpm",
                mode: mode,
                score: firstRHR.quantity.scaledPercent(lower: max, upper: min)
            )
        } else {
            rhrStatus = VitalStatusData(
                name: "Resting Heart Rate",
                value: "No Data",
                mode: .insufficientData,
                score: nil
            )
        }
    }
}
