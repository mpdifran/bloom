//
//  BloodPressureCategory.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-26.
//

import SwiftUI

public enum BloodPressureCategory: CaseIterable, Identifiable {
  public var id: Self { self }

  case low
  case normal
  case elevated
  case hypertensionStage1
  case hypertensionStage2
  case hypertensiveCrisis

  public var name: String {
    switch self {
    case .low:
      String(localized: "Low", bundle: Bundle.coreHealth)
    case .normal:
      String(localized: "Normal", bundle: Bundle.coreHealth)
    case .elevated:
      String(localized: "Elevated", bundle: Bundle.coreHealth)
    case .hypertensionStage1:
      String(localized: "Hypertension Stage 1", bundle: Bundle.coreHealth)
    case .hypertensionStage2:
      String(localized: "Hypertension Stage 2", bundle: Bundle.coreHealth)
    case .hypertensiveCrisis:
      String(localized: "Hypertensive Crisis", bundle: Bundle.coreHealth)
    }
  }

  public var color: Color {
    switch self {
    case .low, .elevated: return .vitalWarning
    case .normal: return .vitalGood
    case .hypertensionStage1, .hypertensionStage2: return .vitalSevere
    case .hypertensiveCrisis: return .pink
    }
  }

  public var description: String {
    switch self {
    case .low:
      String(localized: "Low blood pressure can be normal for some people, especially if they have no symptoms. However, when blood pressure drops too low, it can cause inadequate blood flow to the organs, leading to symptoms like dizziness, fainting, and in severe cases, shock.", bundle: Bundle.coreHealth)
    case .normal:
      String(localized: "This range is considered optimal and indicates that the heart is functioning well without excessive strain on the blood vessels.", bundle: Bundle.coreHealth)
    case .elevated:
      String(localized: "Blood pressure in this range is higher than normal but not yet in the high blood pressure range. It suggests that there may be an increased risk of developing hypertension.", bundle: Bundle.coreHealth)
    case .hypertensionStage1:
      String(localized: "This stage indicates the beginning of high blood pressure, where there’s increased force on the arteries, potentially leading to health issues if not managed.", bundle: Bundle.coreHealth)
    case .hypertensionStage2:
      String(localized: "Blood pressure at this stage is significantly high, posing a greater risk for heart disease, stroke, and other complications. It often requires medication and lifestyle changes to control.", bundle: Bundle.coreHealth)
    case .hypertensiveCrisis:
      String(localized: "This is a critical condition where blood pressure is dangerously high, requiring immediate medical attention to prevent severe damage to organs.", bundle: Bundle.coreHealth)
    }
  }
}
