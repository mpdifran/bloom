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

  private let experiments: [Experiment] = [
    Experiment(
      id: .ExperimentID.onboardingHealthKitView,
      name: "Onboarding HealthKit View AB Test",
      isEnabled: false,
      treatmentPercentage: 0.5
    ),
    Experiment(
      id: .ExperimentID.softerHealthKitView,
      name: "Softer HealthKit View",
      isEnabled: true,
      treatmentPercentage: 0.5
    )
  ]

  private let overrideVariant: ExperimentVariant?
  
  init(overrideVariant: ExperimentVariant? = nil) {
    self.overrideVariant = overrideVariant
  }

  func variant(for experimentId: String) -> ExperimentVariant {
    // In override mode, always return the override variant
    if let overrideVariant = overrideVariant {
      return overrideVariant
    }
    
    // Check for developer override first
    if let override = checkOverride(for: experimentId) {
      print("[ExperimentManager] Using override for \(experimentId): \(override)")
      return override
    }
    
    guard let experiment = experiments.first(where: { $0.id == experimentId }),
          experiment.isEnabled else {
      print("[ExperimentManager] WARNING: Experiment '\(experimentId)' not found or disabled. Available experiments: \(experiments.map { $0.id })")
      return .control
    }

    let userId = UserID.value
    let hashValue = StableHashGenerator.stableHash(experimentId: experimentId, userId: userId)
    let normalizedValue = Double(hashValue) / Double(UInt64.max)
    
    return normalizedValue < experiment.treatmentPercentage ? ExperimentVariant.treatment : .control
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

// Convenience extension for non-async contexts
extension String {
  enum ExperimentID {
    static let onboardingHealthKitView = "onboarding_healthkit_view"
    static let softerHealthKitView = "softer_healthkit_view"
  }
}

// Extension to get all experiments for developer settings
extension ExperimentManager {
  func allExperiments() -> [Experiment] {
    return experiments
  }
}
