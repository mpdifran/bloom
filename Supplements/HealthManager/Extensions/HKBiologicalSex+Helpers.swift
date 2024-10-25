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

    var personName: String {
        switch self {
        case .notSet:
            "person"
        case .female:
            "woman"
        case .male:
            "man"
        case .other:
            "person"
        @unknown default:
            "person"
        }
    }
}
