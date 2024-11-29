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

extension HKUnit {

    var descriptiveUnitName: String {
        switch self {
        case .count():
            "Steps"
        case.fluidOunceUS():
            "oz (US)"
        case .fluidOunceImperial():
            "oz (UK)"
        default:
            unitString
        }
    }

    var sensibleUnitString: String {
        switch self {
        case .count():
            "Steps"
        case.fluidOunceUS():
            "oz"
        case .fluidOunceImperial():
            "oz"
        default:
            unitString
        }
    }

    @MainActor
    func localizedUnit() -> HKUnit {
        switch self {
        case .meterUnit(with: .kilo), .mile():
            return HealthUnitPreferences.shared.distanceUnit
        case .literUnit(with: .milli), .fluidOunceUS(), .fluidOunceImperial():
            return HealthUnitPreferences.shared.liquidVolumeUnit
        case .gramUnit(with: .kilo), .pound():
            return HealthUnitPreferences.shared.weightUnit
        default:
            return self
        }
    }
}
