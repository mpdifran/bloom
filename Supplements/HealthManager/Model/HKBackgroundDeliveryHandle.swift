//
//  HKBackgroundDeliveryHandle.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-23.
//

import Foundation
import HealthKit

class HKBackgroundDeliveryHandle: @unchecked Sendable {
    let objectTypes: [HKObjectType]
    let onDeinit: () -> Void

    init(
        objectTypes: [HKObjectType],
        onDeinit: @escaping () -> Void
    ) {
        self.objectTypes = objectTypes
        self.onDeinit = onDeinit
    }

    deinit {
        onDeinit()
//        for objectType in objectTypes {
//            healthStore?.disableBackgroundDelivery(for: objectType) { success, error in
//                if let error {
//                    print(error)
//                }
//            }
//        }
    }
}
