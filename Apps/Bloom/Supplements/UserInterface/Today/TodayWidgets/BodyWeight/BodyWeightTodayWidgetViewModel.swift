//
//  BodyWeightTodayWidgetViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-17.
//

import SwiftUI
@preconcurrency import HealthKit

extension BodyWeightTodayWidgetView {
    @Observable @MainActor
    final class ViewModel {
        var latestWeight: HKQuantitySample?
        var lastMonthWeightSamples = [DateQuantitySample]()

        init() {
            observeValues()
        }

        private var weightObservationHandler: HKObserverQueryHandle?
    }
}

private extension BodyWeightTodayWidgetView.ViewModel {

    func observeValues() {
        weightObservationHandler = HealthManager.shared.healthStore.observeChanges(
            sampleTypes: [HKQuantityType(.bodyMass)],
            startDate: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
        ) { [weak self] in
            await self?.loadWeightValues()
        }
    }

    func loadWeightValues() async {
        let latestSample = await HealthStoreFetcher.shared.fetchLatestSample(for: .bodyMass)

        let samples = await HealthStoreFetcher.shared.fetchCollatedAverage(
            quantityType: .bodyMass,
            unit: .pound(),
            dateRange: .trailingMonthsFromNow(1)
        )

        self.latestWeight = latestSample
        self.lastMonthWeightSamples = samples
    }
}
