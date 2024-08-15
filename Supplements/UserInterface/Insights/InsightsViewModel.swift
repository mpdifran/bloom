//
//  InsightsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import Foundation
import HealthKit

final class InsightsViewModel: ObservableObject {
    static let shared = InsightsViewModel()

    @Published var sleepAnalysis = [SleepAnalysis]()
    @Published var workoutSummary = [WorkoutSummary]()
    @Published var timeInDaylight = [DateQuantitySampleLegacy]()
    @Published var restingHeartRate = [DateQuantitySampleLegacy]()
    @Published var meditationMinutes = [DateQuantitySampleLegacy]()

    private init() {
        HealthManager.shared.$sleepAnalysis7Days
            .map { $0 ?? [] }
            .receive(on: DispatchQueue.main)
            .assign(to: &$sleepAnalysis)
        observeData()
    }
}

extension InsightsViewModel {

    func observeData() {
        do {
            try HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.timeInDaylight)) {
                let timeInDaylight = await HealthManager.shared.fetchTimeInDaylight()
                await MainActor.run {
                    self.timeInDaylight = timeInDaylight
                }
            }
        } catch {
            print(error)
        }
        do {
            try HealthManager.shared.healthStore.observeChanges(sampleType: HKObjectType.workoutType()) {
                let workoutSummary = await HealthManager.shared.fetchWorkoutSummaryLastTwoWeeks()
                await MainActor.run {
                    self.workoutSummary = workoutSummary
                }
            }
        } catch {
            print(error)
        }
        do {
            try HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.restingHeartRate)) {
                let restingHeartRate = await HealthManager.shared.fetchRestingHeartRate(period: 14)
                await MainActor.run {
                    self.restingHeartRate = restingHeartRate
                }
            }
        } catch {
            print(error)
        }
        do {
            try HealthManager.shared.healthStore.observeChanges(sampleType: HKCategoryType(.mindfulSession)) {
                let meditationMinutes = await HealthManager.shared.fetchMeditationMinutes(periodDays: 14)
                await MainActor.run {
                    self.meditationMinutes = meditationMinutes
                }
            }
        } catch {
            print(error)
        }
    }
}
