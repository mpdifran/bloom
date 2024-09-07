//
//  ActionsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-07.
//

import Foundation
import HealthKit

struct ActionLatestValueDetails {
    let displayString: String
    let timestamp: Date
}

@MainActor
final class ActionsViewModel: ObservableObject {

    @Published var weightDetails: ActionLatestValueDetails?
    @Published var bloodPressureDetails: ActionLatestValueDetails?
    @Published var waterDetails: ActionLatestValueDetails?
    @Published var bowelMovementDetails: ActionLatestValueDetails?

    private var observers = [HKObserverQueryHandle]()

    init() {
        observeData()
    }
}

extension ActionsViewModel {

    func observeData() {
        observers.removeAll()

        let weightHandle = HealthManager.shared.healthStore.observeChanges(
            sampleType: HKQuantityType(.bodyMass),
            dateRange: .trailingMonthsFromNow(1),
            frequency: .immediate
        ) {
            let latestSample = try? await HealthManager.shared.healthStore.fetchLatestSample(for: .bodyMass)
            if let quantitySample = latestSample as? HKQuantitySample {
                let displayString = quantitySample.quantity.displayString(for: .pound())
                let timestamp = quantitySample.startDate
                await MainActor.run {
                    self.weightDetails = ActionLatestValueDetails(displayString: displayString, timestamp: timestamp)
                }
            } else {
                await MainActor.run {
                    self.weightDetails = nil
                }
            }
        }
        observers.append(weightHandle)

        let bloodPressureHandle = HealthManager.shared.healthStore.observeChanges(
            sampleTypes: [HKQuantityType(.bloodPressureSystolic), HKQuantityType(.bloodPressureDiastolic)],
            dateRange: .trailingMonthsFromNow(1),
            frequency: .immediate
        ) {
            let latestSystolic = try? await HealthManager.shared.healthStore.fetchLatestSample(for: .bloodPressureSystolic)
            let latestDiastolic = try? await HealthManager.shared.healthStore.fetchLatestSample(for: .bloodPressureSystolic)

            if
                let systolicQuantitySample = latestSystolic as? HKQuantitySample,
                let diastolicQuantitySample = latestDiastolic as? HKQuantitySample
            {
                let displayString = "\(systolicQuantitySample.quantity.doubleValue(for: .millimeterOfMercury()))/\(diastolicQuantitySample.quantity.doubleValue(for: .millimeterOfMercury()))"
                let timestamp = max(systolicQuantitySample.startDate, diastolicQuantitySample.startDate)

                self.bloodPressureDetails = .init(displayString: displayString, timestamp: timestamp)
            } else {
                self.bloodPressureDetails = nil
            }
        }
        observers.append(bloodPressureHandle)

        let waterHandle = HealthManager.shared.healthStore.observeChanges(
            sampleType: HKQuantityType(.dietaryWater),
            dateRange: .trailingMonthsFromNow(1),
            frequency: .immediate
        ) {
            let latestSample = try? await HealthManager.shared.healthStore.fetchLatestSample(for: .dietaryWater)
            if let quantitySample = latestSample as? HKQuantitySample {
                let displayString = quantitySample.quantity.displayString(for: .literUnit(with: .milli))
                let timestamp = quantitySample.startDate
                await MainActor.run {
                    self.waterDetails = ActionLatestValueDetails(displayString: displayString, timestamp: timestamp)
                }
            } else {
                await MainActor.run {
                    self.waterDetails = nil
                }
            }
        }
        observers.append(waterHandle)

        Task {
            let bowelMovements = try? await DataFetcher.shared.fetchBowelMovements(dateRange: .trailingMonthsFromNow(1))

            if let lastSample = bowelMovements?.last {
                let displayString = "Type \(lastSample.bristolStoolType)"
                let timestamp = lastSample.date

                await MainActor.run {
                    self.bowelMovementDetails = .init(displayString: displayString, timestamp: timestamp)
                }
            } else {
                await MainActor.run {
                    self.bowelMovementDetails = nil
                }
            }
        }
    }
}
