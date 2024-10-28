//
//  ToDoModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-10.
//

import SwiftUI
import HealthKit
import DataContainer

struct ToDoModel: Codable, Identifiable, Hashable {
    var id: Int { hashValue }

    let kind: Kind
    var cadence: Cadence
    let vitalKind: VitalModel.Kind?
}

extension ToDoModel {
    enum Cadence: String, Codable, CaseIterable, Identifiable {
        var id: Self { self }

        case daily
        case everySunday
        case everyMonday
        case everyTuesday
        case everyWednesday
        case everyThursday
        case everyFriday
        case everySaturday
        case everyThreeDays
        case everySevenDays
        case never

        var name: String {
            switch self {
            case .everySunday:
                "Every Sunday"
            case .everyMonday:
                "Every Monday"
            case .everyTuesday:
                "Every Tuesday"
            case .everyWednesday:
                "Every Wednesday"
            case .everyThursday:
                "Every Thursday"
            case .everyFriday:
                "Every Friday"
            case .everySaturday:
                "Every Saturday"
            case .everyThreeDays:
                "Every 3 Days"
            case .everySevenDays:
                "Every 7 Days"
            default:
                rawValue.capitalized
            }
        }
    }

    enum Kind: String, Codable {
        case logWeight
        case logBloodPressure
        case logFood
        case logProtein

        var name: String {
            switch self {
            case .logWeight: "Log Weight"
            case .logBloodPressure: "Record Blood Pressure"
            case .logFood: "Log Food"
            case .logProtein: "Log Protein"
            }
        }

        var systemImage: String {
            switch self {
            case .logWeight: "gauge.with.dots.needle.bottom.50percent.badge.plus"
            case .logBloodPressure: "gauge.open.with.lines.needle.67percent.and.arrowtriangle"
            case .logFood: "fork.knife"
            case .logProtein: "fork.knife"
            }
        }

        var color: Color {
            switch self {
            case .logWeight: .mutedIndigo
            case .logBloodPressure: .mutedPink
            case .logFood: .mutedGreen
            case .logProtein: .protein
            }
        }

        var sampleTypes: [HKSampleType] {
            switch self {
            case .logWeight: [HKQuantityType(.bodyMass)]
            case .logBloodPressure: [HKQuantityType(.bloodPressureSystolic), HKQuantityType(.bloodPressureDiastolic)]
            case .logFood: [HKQuantityType(.dietaryEnergyConsumed)]
            case .logProtein: [HKQuantityType(.dietaryProtein)]
            }
        }

        @MainActor
        var sheetToPresent: AnyView {
            switch self {
            case .logWeight: BodyWeightActionCardView().asAny
            case .logBloodPressure: BloodPressureActionCardView().asAny
            case .logFood: MFPRecommendationActionCard().asAny
            case .logProtein: MFPRecommendationActionCard().asAny
            }
        }
    }
}
