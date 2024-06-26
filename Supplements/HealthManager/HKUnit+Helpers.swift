//
//  HKUnit+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-26.
//

import Foundation
import HealthKit

extension HKUnit {

    static func bpm() -> HKUnit {
        HKUnit.count().unitDivided(by: HKUnit.minute())
    }
}
