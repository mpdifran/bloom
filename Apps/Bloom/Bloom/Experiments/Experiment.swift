//
//  Experiment.swift
//  Bloom
//
//  Created by Claude on 2025-08-26.
//

import Foundation

enum ExperimentVariant: String, CaseIterable {
  case control
  case treatment
}

enum Experiment: String, CaseIterable, Identifiable {
  case onboardingFeaturePitch = "onboarding_feature_pitch"
  case periodicPaywall = "periodic_paywall"

  var name: String {
    switch self {
    case .onboardingFeaturePitch:
      return "Onboarding Feature Pitch"
    case .periodicPaywall:
      return "Periodic Paywall"
    }
  }

  var id: ExperimentIdentifier {
    ExperimentIdentifier(self.rawValue)
  }
}

extension ExperimentIdentifier {
  static let onboardingFeaturePitch = Experiment.onboardingFeaturePitch.id
  static let periodicPaywall = Experiment.periodicPaywall.id
}
