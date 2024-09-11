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
    let timestampString: String
}

@MainActor
final class ActionsViewModel: ObservableObject {
    static let shared = ActionsViewModel()


    @Published var weightDetails: ActionLatestValueDetails?
    @Published var bloodPressureDetails: ActionLatestValueDetails?
    @Published var waterDetails: ActionLatestValueDetails?
    @Published var bowelMovementDetails: ActionLatestValueDetails?

    private var observers = [HKObserverQueryHandle]()

    private init() {
        observeData()
    }
}

extension ActionsViewModel {

    func observeData() {
        observers.removeAll()

        let weightHandle = HealthManager.shared.healthStore.observeChanges(
            sampleType: HKQuantityType(.bodyMass),
            startDate: Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
        ) {
            let latestSample = try? await HealthManager.shared.healthStore.fetchLatestSample(for: .bodyMass)
            if let quantitySample = latestSample as? HKQuantitySample {
                let displayString = quantitySample.quantity.displayString(for: .pound(), hasNoDecimalPlaces: false)
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

                self.bloodPressureDetails = .init(
                    displayString: displayString,
                    timestampString: timestampString
                )
            } else {
                self.bloodPressureDetails = nil
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
                let displayString = quantity.displayString(for: .literUnit(with: .milli))

                await MainActor.run {
                    self.waterDetails = ActionLatestValueDetails(
                        displayString: displayString,
                        timestampString: "Today"
                    )
                }
            } else {
                await MainActor.run {
                    self.waterDetails = ActionLatestValueDetails(
                        displayString: "0 mL",
                        timestampString: "Today"
                    )
                }
            }
        }
        observers.append(waterHandle)

        Task {
            let bowelMovements = try? await DataFetcher.shared.fetchBowelMovements(dateRange: .trailingMonthsFromNow(1))

            if let lastSample = bowelMovements?.last {
                let displayString = "Type \(lastSample.bristolStoolType)"
                let timestamp = DateFormatter.relativeDateTimeShort.string(from: lastSample.date)

                await MainActor.run {
                    self.bowelMovementDetails = .init(displayString: displayString, timestampString: timestamp)
                }
            } else {
                await MainActor.run {
                    self.bowelMovementDetails = nil
                }
            }
        }
    }
}
