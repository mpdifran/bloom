//
//  TodayViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-01.
//

import Foundation
import HealthKit

@MainActor
final class TodayViewModel: ObservableObject {
    static let shared = TodayViewModel()

    @Published var hasLoggedBodyWeight = false

    private var observers = [HKObserverQueryHandle]()

    private init() {
        observeData()
    }
}

extension TodayViewModel {

    func observeData() {
        observers.removeAll(keepingCapacity: true)

        let weightObserver = HealthManager.shared.healthStore.observeChanges(sampleType: HKQuantityType(.bodyMass), dateRange: .today(), frequency: .immediate) {
            let sample = try? await HealthManager.shared.healthStore.fetchLatestSample(for: .bodyMass)

            await MainActor.run { [weak self] in
                guard let sample else { self?.hasLoggedBodyWeight = false; return }

                self?.hasLoggedBodyWeight = Calendar.current.isDateInToday(sample.startDate)
            }
        }
        observers.append(weightObserver)
    }
}
