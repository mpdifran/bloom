//
//  HKBackgroundDeliveryHandle.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-23.
//

import Foundation
import HealthKit

class HKBackgroundDeliveryHandle {
    let objectTypes: [HKObjectType]
    weak var healthStore: HKHealthStore?

    init(
        objectTypes: [HKObjectType],
        healthStore: HKHealthStore?
    ) {
        self.objectTypes = objectTypes
        self.healthStore = healthStore
    }

    deinit {
        for objectType in objectTypes {
            healthStore?.disableBackgroundDelivery(for: objectType) { success, error in
                if let error {
                    print(error)
                }
            }
        }
    }
}
