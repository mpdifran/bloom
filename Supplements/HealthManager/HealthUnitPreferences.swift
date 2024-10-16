//
//  HealthUnitPreferences.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-15.
//

import Foundation
import HealthKit

private extension String {
    enum Key {
        static let distanceUnit = "HealthUnitPreferences.distanceUnit"
        static let liquidVolumeUnit = "HealthUnitPreferences.liquidVolumeUnit"
        static let weightUnit = "HealthUnitPreferences.weightUnit"
    }
}

@MainActor @Observable
final class HealthUnitPreferences {
    static let shared = HealthUnitPreferences()

    var distanceUnit: HKUnit {
        didSet {
            UserDefaults.group.set(distanceUnit.unitString, forKey: .Key.distanceUnit)
            recalculateVitals()
        }
    }
    var liquidVolumeUnit: HKUnit {
        didSet {
            UserDefaults.group.set(liquidVolumeUnit.unitString, forKey: .Key.liquidVolumeUnit)
            recalculateVitals()
        }
    }
    var weightUnit: HKUnit {
        didSet {
            UserDefaults.group.set(weightUnit.unitString, forKey: .Key.weightUnit)
            recalculateVitals()
        }
    }

    private init() {
        if let unitString = UserDefaults.group.string(forKey: .Key.distanceUnit) {
            distanceUnit = HKUnit(from: unitString)
        } else {
            if Locale.current.measurementSystem == .metric {
                distanceUnit = .meterUnit(with: .kilo)
            } else {
                distanceUnit = .mile()
            }
        }
        if let unitString = UserDefaults.group.string(forKey: .Key.liquidVolumeUnit) {
            liquidVolumeUnit = HKUnit(from: unitString)
        } else {
            switch Locale.current.measurementSystem {
            case .us:
                liquidVolumeUnit = .fluidOunceUS()
            case .uk:
                liquidVolumeUnit = .fluidOunceImperial()
            default:
                liquidVolumeUnit = .literUnit(with: .milli)
            }
        }
        if let unitString = UserDefaults.group.string(forKey: .Key.weightUnit) {
            weightUnit = HKUnit(from: unitString)
        } else {
            if Locale.current.measurementSystem == .metric {
                weightUnit = .gramUnit(with: .kilo)
            } else {
                weightUnit = .pound()
            }
        }
    }
}

private extension HealthUnitPreferences {

    func recalculateVitals() {
        Task {
            await VitalsCalculator.shared.recalculateVitals()
        }
    }
}

extension HKUnit {

    static var distanceUnits: [HKUnit] {
        [
            .meterUnit(with: .kilo),
            .mile()
        ]
    }

    static var liquidVolumeUnits: [HKUnit] {
        [
            .literUnit(with: .milli),
            .fluidOunceUS(),
            .fluidOunceImperial()
        ]
    }

    static var weightUnits: [HKUnit] {
        [
            .gramUnit(with: .kilo),
            .pound()
        ]
    }
}
