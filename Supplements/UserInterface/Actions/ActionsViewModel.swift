//
//  ActionsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-07.
//

import Foundation
@preconcurrency import HealthKit
import DataContainer
import SwiftData

struct ActionLatestValueDetails: Sendable {
    let displayString: String
    let timestampString: String
}

extension ActionsView {
    @Observable @MainActor
    final class ViewModel {
        var weightDetails: ActionLatestValueDetails?
        var bloodPressureDetails: ActionLatestValueDetails?
        var waterDetails: ActionLatestValueDetails?
        var bowelMovementDetails: ActionLatestValueDetails?

        private var observers = [HKObserverQueryHandle]()

        let modelContext = ModelContext(ContainerHolder.shared.container)

        init() {
            observeData()
        }
    }
}

extension ActionsView.ViewModel {

    func observeData() {
        observers.removeAll()

        let weightHandle = HealthManager.shared.healthStore.observeChanges(
            sampleType: HKQuantityType(.bodyMass),
            startDate: Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
        ) {
            let latestSample = try? await HealthManager.shared.healthStore.fetchLatestSample(for: .bodyMass)
            if let quantitySample = latestSample as? HKQuantitySample {
                let displayString = await quantitySample.quantity.displayString(for: .pound(), formatter: .oneDecimalPlace)
                let timestamp = DateFormatter.relativeDateTimeShort.string(from: quantitySample.startDate)

                await MainActor.run {
                    self.weightDetails = ActionLatestValueDetails(
                        displayString: displayString,
                        timestampString: timestamp
                    )
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
            startDate: Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
        ) {
            let latestSystolic = try? await HealthManager.shared.healthStore.fetchLatestSample(for: .bloodPressureSystolic)
            let latestDiastolic = try? await HealthManager.shared.healthStore.fetchLatestSample(for: .bloodPressureDiastolic)

            if
                let systolicQuantitySample = latestSystolic as? HKQuantitySample,
                let diastolicQuantitySample = latestDiastolic as? HKQuantitySample
            {
                let displayString = "\(systolicQuantitySample.quantity.doubleValue(for: .millimeterOfMercury()).format())/\(diastolicQuantitySample.quantity.doubleValue(for: .millimeterOfMercury()).format())"
                let timestamp = max(systolicQuantitySample.startDate, diastolicQuantitySample.startDate)

                let timestampString = DateFormatter.relativeDateTimeShort.string(from: timestamp)

                await MainActor.run {
                    self.bloodPressureDetails = .init(
                        displayString: displayString,
                        timestampString: timestampString
                    )
                }
            } else {
                await MainActor.run {
                    self.bloodPressureDetails = nil
                }
            }
        }
        observers.append(bloodPressureHandle)

        let waterHandle = HealthManager.shared.healthStore.observeChanges(
            sampleType: HKQuantityType(.dietaryWater),
            startDate: Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
        ) {
            let quantity = try? await HealthManager.shared.healthStore.fetchQuantity(
                for: .dietaryWater,
                dateRange: .today(),
                option: .cumulativeSum
            )
            if let quantity {
                let displayString = await quantity.displayString(for: .literUnit(with: .milli))

                await MainActor.run {
                    self.waterDetails = ActionLatestValueDetails(
                        displayString: displayString,
                        timestampString: "Today"
                    )
                }
            } else {
                await MainActor.run {
                    let emptyQuantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: 0)
                    self.waterDetails = ActionLatestValueDetails(
                        displayString: emptyQuantity.displayString(for: .literUnit(with: .milli)),
                        timestampString: "Today"
                    )
                }
            }
        }
        observers.append(waterHandle)

        Task {
            let modelActor = BowelMovementModelActor.standard()
            let bowelMovements = try? await modelActor.fetchBowelMovements(dateRange: .trailingMonthsFromNow(1))

            if let lastSample = bowelMovements?.last {
                let displayString = "Type \(lastSample.bristolStoolType)"
                let timestamp = DateFormatter.relativeDateTimeShort.string(from: lastSample.date)
                let details = ActionLatestValueDetails(displayString: displayString, timestampString: timestamp)

                await MainActor.run {
                    self.bowelMovementDetails = details
                }
            } else {
                await MainActor.run {
                    self.bowelMovementDetails = nil
                }
            }
        }
    }
}
