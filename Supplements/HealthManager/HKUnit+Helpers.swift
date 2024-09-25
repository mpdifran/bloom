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

    static func breathsPerMinute() -> HKUnit {
        HKUnit.count().unitDivided(by: HKUnit.minute())
    }

    static func vo2Max() -> HKUnit {
        HKUnit(from: "mL/min·kg")
    }

    static func mgPerDL() -> HKUnit {
        .gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
    }

    static func millisecond() -> HKUnit {
        .secondUnit(with: .milli)
    }
}
