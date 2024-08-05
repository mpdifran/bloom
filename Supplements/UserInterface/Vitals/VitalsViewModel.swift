//
//  VitalsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-22.
//

import SwiftUI
import HealthKit
import Combine

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

    @Published var energyBurnedSummary: EnergyBurnedSummary?
    @Published var sleepVitalsSummary: SleepVitalsMonthlySummary?
    @Published var cardioFitnessSummary: CardioFitnessMonthlySummary?
    @Published var bodyFatPercentageSummary: BodyCompositionMonthlySummary?
    @Published var mobilitySummary: MobilityMonthlySummary?
    @Published var stressSummary: StressMonthlySummary?
    @Published var nutritionSummary: NutritionMonthlySummary?

    @Published var heartRateVariability = [DateQuantitySampleLegacy]()
    @Published var restingHeartRate = [DateQuantitySampleLegacy]()
    @Published var basalEnergyBurned: (Double, Int)?
    @Published var activeEnergyBurned: (Double, Int)?
    @Published var lastMonthBasalEnergyBurned: (Double, Int)?
    @Published var lastMonthActiveEnergyBurned: (Double, Int)?

    private var cancellables = Set<AnyCancellable>()

    private init() {
        observeData()
    }
}

private extension VitalsViewModel {

    func observeData() {
        do {
            try HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.heartRateVariabilitySDNN)) {
                let heartRateVariability = await HealthManager.shared.fetchHeartRateVariability(periodDays: 28)
                await MainActor.run {
                    self.heartRateVariability = heartRateVariability
                }
            }
        } catch {
            print(error)
        }
        do {
            try HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.restingHeartRate)) {
                let restingHeartRate = await HealthManager.shared.fetchRestingHeartRate(period: 28)
                await MainActor.run {
                    self.restingHeartRate = restingHeartRate
                }
            }
        } catch {
            print(error)
        }

        HealthManager.shared.$sleepAnalysis7Days
            .combineLatest($heartRateVariability, $restingHeartRate)
            .sink(receiveValue: { [weak self] (sleepAnalysis, heartRateVariability, restingHeartRate) in
                self?.createVitalStatuses(
                    sleepAnalysis: sleepAnalysis ?? [],
                    heartRateVariability: heartRateVariability,
                    restingHeartRate: restingHeartRate
                )
            })
            .store(in: &cancellables)

        do {
            try HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.basalEnergyBurned)) {
                let basalEnergyBurned = await HealthManager.shared.fetchBasalEnergy()
                let lastMonthBasalEnergyBurned = await HealthManager.shared.fetchBasalEnergy(numPastMonths: 1)
                await MainActor.run {
                    self.basalEnergyBurned = basalEnergyBurned
                    self.lastMonthBasalEnergyBurned = lastMonthBasalEnergyBurned
                }
            }
        } catch {
            print(error)
        }
        do {
            try HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.activeEnergyBurned)) {
                let activeEnergyBurned = await HealthManager.shared.fetchActiveEnergy()
                let lastMonthActiveEnergyBurned = await HealthManager.shared.fetchActiveEnergy(numPastMonths: 1)
                await MainActor.run {
                    self.activeEnergyBurned = activeEnergyBurned
                    self.lastMonthActiveEnergyBurned = lastMonthActiveEnergyBurned
                }
            }
        } catch {
            print(error)
        }

        $basalEnergyBurned
            .combineLatest($activeEnergyBurned, $lastMonthBasalEnergyBurned, $lastMonthActiveEnergyBurned)
            .map { (basalEnergy, activeEnergy, lastMonthBasalEnergy, lastMonthActiveEnergy) in
                guard
                    let basalEnergy,
                    let activeEnergy,
                    let lastMonthBasalEnergy,
                    let lastMonthActiveEnergy
                else { return nil }

                return EnergyBurnedSummary(
                    averageBasalEnergyBurned: basalEnergy.0,
                    averageActiveEnergyBurned: activeEnergy.0,
                    lastMonthAverageBasalEnergyBurned: lastMonthBasalEnergy.0,
                    lastMonthAverageActiveEnergyBurned: lastMonthActiveEnergy.0
                )
            }
            .assign(to: &$energyBurnedSummary)

        HealthManager.shared.$sleepAnalysis30Days
            .combineLatest(HealthManager.shared.$sleepAnalysisPrevious30Days)
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

        do {
            try HealthManager.shared.healthStore.observeChanges(
                sampleTypes: [
                    HKCategoryType(.appleWalkingSteadinessEvent),
                    HKQuantityType(.sixMinuteWalkTestDistance),
                    HKQuantityType(.walkingDoubleSupportPercentage)
                ]
            ) {
                let summary = await HealthManager.shared.fetchMonthlyMobilitySummary()
                await MainActor.run {
                    self.mobilitySummary = summary
                }
            }
        } catch {
            print(error)
        }

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
            try HealthManager.shared.healthStore.observeChanges(sampleTypes: HealthManager.shared.nutritionTypes) {
                let summary = await HealthManager.shared.fetchNutritionMonthlySummary()
                await MainActor.run {
                    self.nutritionSummary = summary
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

        $energyBurnedSummary
            .sink { [weak self] (_) in
                self?.createVitals()
            }
            .store(in: &cancellables)
        $sleepVitalsSummary
            .sink { [weak self] (_) in
                self?.createVitals()
            }
            .store(in: &cancellables)
        $cardioFitnessSummary
            .sink { [weak self] (_) in
                self?.createVitals()
            }
            .store(in: &cancellables)
        $bodyFatPercentageSummary
            .sink { [weak self] (_) in
                self?.createVitals()
            }
            .store(in: &cancellables)
        $mobilitySummary
            .sink { [weak self] (_) in
                self?.createVitals()
            }
            .store(in: &cancellables)
        $stressSummary
            .sink { [weak self] (_) in
                self?.createVitals()
            }
            .store(in: &cancellables)
        $nutritionSummary
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
        if let energyBurnedSummary {
            vitals.append(
                VitalModel(
                    id: .activityLevel,
                    subtitle: energyBurnedSummary.subtitle,
                    status: energyBurnedSummary.activityLevel.name,
                    score: energyBurnedSummary.score,
                    color: energyBurnedSummary.activityLevel.color,
                    trend: energyBurnedSummary.trend
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

        self.vitals = vitals.sorted(by: { $0.score < $1.score })
    }

    func createVitalStatuses(
        sleepAnalysis: [SleepAnalysis],
        heartRateVariability: [DateQuantitySampleLegacy],
        restingHeartRate: [DateQuantitySampleLegacy]
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
