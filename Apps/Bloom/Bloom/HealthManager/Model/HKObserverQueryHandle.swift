//
//  HKObserverQueryHandle.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-23.
//

import Foundation
@preconcurrency import HealthKit

class HKObserverQueryHandle: @unchecked Sendable {
    let queries: [HKObserverQuery]
    weak var healthStore: HKHealthStore?

    init(
        queries: [HKObserverQuery],
        healthStore: HKHealthStore
    ) {
        self.queries = queries
        self.healthStore = healthStore
    }

    deinit {
        queries.forEach {
            healthStore?.stop($0)
        }
    }
}

extension HKObserverQueryHandle {

    func store(in holder: inout [HKObserverQueryHandle]) {
        holder.append(self)
    }
}
