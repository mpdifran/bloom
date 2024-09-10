//
//  ToDoModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-10.
//

import SwiftUI
import HealthKit

struct ToDoModel: Codable, Identifiable, Hashable {
    var id: Int { hashValue }

    let kind: Kind
    var cadence: Cadence
}

extension ToDoModel {
    enum Cadence: String, Codable, CaseIterable, Identifiable {
        var id: Self { self }

        case daily
        case weekly
        case never

        var name: String {
            rawValue.capitalized
        }
    }

    enum Kind: String, Codable {
        case logWeight
        case logBloodPressure

        var name: String {
            switch self {
            case .logWeight: "Log Weight"
            case .logBloodPressure: "Record Blood Pressure"
            }
        }

        var systemImage: String {
            switch self {
            case .logWeight: "gauge.with.dots.needle.bottom.50percent.badge.plus"
            case .logBloodPressure: "gauge.open.with.lines.needle.67percent.and.arrowtriangle"
            }
        }

        var color: Color {
            switch self {
            case .logWeight: .mutedIndigo
            case .logBloodPressure: .mutedPink
            }
        }

        var sampleTypes: [HKSampleType] {
            switch self {
            case .logWeight: [HKQuantityType(.bodyMass)]
            case .logBloodPressure: [HKQuantityType(.bloodPressureSystolic), HKQuantityType(.bloodPressureDiastolic)]
            }
        }

        var sheetToPresent: AnyView {
            switch self {
            case .logWeight: BodyWeightActionCardView().asAny
            case .logBloodPressure: BloodPressureActionCardView().asAny
            }
        }
    }
}
