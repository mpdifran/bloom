//
//  ExperimentManager.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-05.
//

import Foundation
import CryptoKit

final actor ExperimentManager {
  static let shared = ExperimentManager()

  private let experiments: [Experiment] = [
    Experiment(
      id: .ExperimentID.onboardingHealthKitView,
      name: "Onboarding HealthKit View AB Test",
      isEnabled: true,
      treatmentPercentage: 0.5
    )
  ]

  private init() {}

  func variant(for experimentId: String) -> ExperimentVariant {
    // Check for developer override first
    if let override = checkOverride(for: experimentId) {
      return override
    }
    
    guard let experiment = experiments.first(where: { $0.id == experimentId }),
          experiment.isEnabled else {
      return .control
    }

    let userId = UserID.value
    let hashValue = stableHash(experimentId: experimentId, userId: userId)
    let normalizedValue = Double(hashValue) / Double(UInt64.max)

    return normalizedValue < experiment.treatmentPercentage ? .treatment : .control
  }
  
  private func checkOverride(for experimentId: String) -> ExperimentVariant? {
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

  private func stableHash(experimentId: String, userId: String) -> UInt64 {
    let input = "\(experimentId):\(userId)"
    let inputData = Data(input.utf8)
    let hash = SHA256.hash(data: inputData)

    // Convert first 8 bytes of hash to UInt64
    let hashData = Data(hash)
    let value = UInt64(bigEndian: hashData.prefix(8).withUnsafeBytes { bytes in
      bytes.load(as: UInt64.self)
    })

    return value
  }
}

// Convenience extension for non-async contexts
extension String {
  enum ExperimentID {
    static let onboardingHealthKitView = "onboarding_healthkit_view"
  }
}

// Extension to get all experiments for developer settings
extension ExperimentManager {
  func allExperiments() -> [Experiment] {
    return experiments
  }
}
