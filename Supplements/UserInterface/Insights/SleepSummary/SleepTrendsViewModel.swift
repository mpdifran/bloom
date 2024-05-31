//
//  SleepTrendsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-30.
//

import Foundation

final class SleepTrendsViewModel: ObservableObject {
    @Published var sleepAnalyses = [SleepAnalysis]()
}

extension SleepTrendsViewModel {

    func loadSleepAnalysis() async {
        let sleepAnalyses = await HealthManager.shared.fetchDailySleepAnalysis(period: 30)

        await MainActor.run {
            self.sleepAnalyses = sleepAnalyses
        }
    }
}
