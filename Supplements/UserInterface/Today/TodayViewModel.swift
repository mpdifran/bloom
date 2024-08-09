//
//  TodayViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-10.
//

import Foundation

final class TodayViewModel: ObservableObject {
    static let shared = TodayViewModel()

    @Published var date = Date.now
    @Published var sleepAnalysis: SleepAnalysis?

    private init() {
        HealthManager.shared.$sleepAnalysis30Days
            .combineLatest($date)
            .receive(on: DispatchQueue(label: "TodayViewModel.SleepAnalysis"))
            .map { (sleepAnalysis30Days, date) in
                sleepAnalysis30Days?.first(where: { sleepAnalysis in
                    Calendar.current.isDate(sleepAnalysis.endDate, inSameDayAs: date)
                })
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$sleepAnalysis)
    }
}
