//
//  HKBiologicalSex+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-25.
//

import HealthKit

extension HKBiologicalSex {

    var name: String {
        switch self {
        case .notSet:
            "Unknown"
        case .female:
            "Female"
        case .male:
            "Male"
        case .other:
            "Other"
        @unknown default:
            "Unknown"
        }
    }

    var personName: String? {
        switch self {
        case .notSet:
            nil
        case .female:
            "female"
        case .male:
            "male"
        case .other:
            nil
        @unknown default:
            nil
        }
    }
}
