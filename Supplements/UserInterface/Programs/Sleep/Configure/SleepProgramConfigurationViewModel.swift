//
//  SleepProgramConfigurationViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-31.
//

import Foundation

final class SleepProgramConfigurationViewModel: ObservableObject {
    @Published var workoutSummary = [WorkoutSummary]()
    @Published var sleepAnalyses = [SleepAnalysis]()
}

extension SleepProgramConfigurationViewModel {

    func loadData() async {
        let workoutSummary = await HealthManager.shared.fetchWorkoutSummaryLastTwoWeeks()
        let sleepAnalyses = await HealthManager.shared.fetchDailySleepAnalysis(period: 14)

        await MainActor.run {
            self.workoutSummary = workoutSummary
            self.sleepAnalyses = sleepAnalyses
        }
    }
}
