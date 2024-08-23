//
//  HKBackgroundDeliveryHandle.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-23.
//

import Foundation
import HealthKit

class HKBackgroundDeliveryHandle {
    let objectType: HKObjectType
    weak var healthStore: HKHealthStore?

    init(
        objectType: HKObjectType,
        healthStore: HKHealthStore?
    ) {
        self.objectType = objectType
        self.healthStore = healthStore
    }

    deinit {
        healthStore?.disableBackgroundDelivery(for: objectType) { success, error in
            if let error {
                print(error)
            }
        }
    }
}
