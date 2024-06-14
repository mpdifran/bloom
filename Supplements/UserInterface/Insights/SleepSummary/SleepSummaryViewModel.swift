//
//  SleepSummaryViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-14.
//

import Foundation

final class SleepSummaryViewModel: ObservableObject {
    static let shared = SleepSummaryViewModel()

    @Published var sleepAnalyses = [SleepAnalysis]()

    private init() {
        HealthManager.shared.$sleepAnalysis7Days
            .map { $0 ?? [] }
            .receive(on: DispatchQueue.main)
            .assign(to: &$sleepAnalyses)
    }
}
