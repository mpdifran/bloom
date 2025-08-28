//
//  ExperimentManager.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-05.
//

import Foundation
import SwiftUI

@MainActor @Observable
final class ExperimentManager {

  private let overrideVariant: ExperimentVariant?
  
  init(overrideVariant: ExperimentVariant? = nil) {
    self.overrideVariant = overrideVariant
  }

  func variant(for identifier: ExperimentIdentifier) -> ExperimentVariant {
    // In override mode, always return the override variant
    if let overrideVariant = overrideVariant {
      return overrideVariant
    }
    
    // Check for developer override first
    if let override = checkOverride(for: identifier.value) {
      print("[ExperimentManager] Using override for \(identifier.value): \(override)")
      return override
    }
    
    // Use default 50/50 split for all experiments
    let treatmentPercentage = 0.5

    let userId = UserID.value
    let hashValue = StableHashGenerator.stableHash(experimentId: identifier.value, userId: userId)
    let normalizedValue = Double(hashValue) / Double(UInt64.max)
    
    return normalizedValue < treatmentPercentage ? ExperimentVariant.treatment : .control
  }
  
  private func checkOverride(for experimentId: String) -> ExperimentVariant? {
    // Only allow overrides if developer mode is enabled
    guard UserDefaults.standard.bool(forKey: .FeatureFlag.developerMode) else {
      return nil
    }
    
    let overrideKey = "ExperimentOverride.\(experimentId)"
    guard let overrideValue = UserDefaults.standard.string(forKey: overrideKey),
          let override = ExperimentOverride(rawValue: overrideValue) else {
      return nil
    }
    
    switch override {
    case .original:
      return nil // Use original logic
    case .control:
      return .control
    case .treatment:
      return .treatment
    }
  }
}


// Extension to get all experiments for developer settings
extension ExperimentManager {
  func allExperiments() -> [Experiment] {
    return Experiment.allCases
  }
}
