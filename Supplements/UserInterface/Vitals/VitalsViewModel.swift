//
//  VitalsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-22.
//

import Foundation
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
    let mode: VitalStatusCell.Mode
}

final class VitalsViewModel: ObservableObject {
    static let shared = VitalsViewModel()

    @Published var hrvStatus: VitalStatusData?
    @Published var sleepStatus: VitalStatusData?
    @Published var rhrStatus: VitalStatusData?

    @Published var heartRateVariability = [DateQuantitySample]()
    @Published var restingHeartRate = [DateQuantitySample]()

    private var cancellables = Set<AnyCancellable>()

    private init() {
        observeData()
    }
}

private extension VitalsViewModel {

    func observeData() {
        do {
            try HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.heartRateVariabilitySDNN), frequency: .immediate) {
                let heartRateVariability = await HealthManager.shared.fetchHeartRateVariability(periodDays: 28)
                await MainActor.run {
                    self.heartRateVariability = heartRateVariability
                }
            }
        } catch {
            print(error)
        }
        do {
            try HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.restingHeartRate), frequency: .immediate) {
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
    }

    func createVitalStatuses(
        sleepAnalysis: [SleepAnalysis],
        heartRateVariability: [DateQuantitySample],
        restingHeartRate: [DateQuantitySample]
    ) {
        if let firstHRV = heartRateVariability.first {
            let average = heartRateVariability.average(keyPath: \.quantity)

            let mode: VitalStatusCell.Mode
            if firstHRV.quantity >= average + .hrvVariance {
                mode = .excel
            } else if firstHRV.quantity < average + .hrvVariance && firstHRV.quantity >= average - .hrvVariance {
                mode = .good
            } else if firstHRV.quantity < average - .hrvVariance && firstHRV.quantity >= average - (.hrvVariance * 2) {
                mode = .warning
            } else {
                mode = .threat
            }

            hrvStatus = VitalStatusData(
                name: "Heart Rate Variability",
                value: "\(String(format: "%.0f", firstHRV.quantity)) ms",
                mode: mode
            )

        } else {
            hrvStatus = VitalStatusData(
                name: "Heart Rate Variability",
                value: "No Data",
                mode: .insufficientData
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
                mode: mode
            )
        } else {
            sleepStatus = VitalStatusData(
                name: "Sleep Quality",
                value: "No Data",
                mode: .insufficientData
            )
        }

        if let firstRHR = restingHeartRate.first {
            let (min, max) = HealthManager.shared.goalRestingHeartRateForUser()

            let mode: VitalStatusCell.Mode
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
                mode: mode
            )
        } else {
            rhrStatus = VitalStatusData(
                name: "Resting Heart Rate",
                value: "No Data",
                mode: .insufficientData
            )
        }
    }
}
