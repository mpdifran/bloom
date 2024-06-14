//
//  SleepTrendsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-30.
//

import Foundation

final class SleepTrendsViewModel: ObservableObject {
    @Published var sleepAnalyses = [SleepAnalysis]()

    init() {
        HealthManager.shared.$sleepAnalysis30Days
            .map { $0 ?? [] }
            .receive(on: DispatchQueue.main)
            .assign(to: &$sleepAnalyses)
    }
}
