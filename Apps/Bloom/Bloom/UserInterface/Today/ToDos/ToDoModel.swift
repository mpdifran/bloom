//
//  ToDoModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-10.
//

import SFSafeSymbols
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
        String(localized: "Every Sunday")
      case .everyMonday:
        String(localized: "Every Monday")
      case .everyTuesday:
        String(localized: "Every Tuesday")
      case .everyWednesday:
        String(localized: "Every Wednesday")
      case .everyThursday:
        String(localized: "Every Thursday")
      case .everyFriday:
        String(localized: "Every Friday")
      case .everySaturday:
        String(localized: "Every Saturday")
      case .everyThreeDays:
        String(localized: "Every 3 Days")
      case .everySevenDays:
        String(localized: "Every 7 Days")
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
      case .logWeight: String(localized: "Log Weight")
      case .logBloodPressure: String(localized: "Log Blood Pressure")
      case .logFood: String(localized: "Log Food")
      case .logProtein: String(localized: "Log Protein")
      }
    }

    var symbol: SFSymbol {
      switch self {
      case .logWeight: .gaugeWithDotsNeedleBottom50percentBadgePlus
      case .logBloodPressure: .gaugeOpenWithLinesNeedle67percentAndArrowtriangle
      case .logFood: .forkKnife
      case .logProtein: .forkKnife
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
      case .logWeight: BodyWeightActionCardView(performDismiss: nil).asAny
      case .logBloodPressure: BloodPressureActionCardView(performDismiss: nil).asAny
      case .logFood: FoodLoggingActionCardView().asAny
      case .logProtein: FoodLoggingActionCardView().asAny
      }
    }

    var requiresBloomPlusEntitlement: Bool {
      switch self {
      case .logWeight, .logBloodPressure, .logFood, .logProtein: false
      }
    }
  }
}
