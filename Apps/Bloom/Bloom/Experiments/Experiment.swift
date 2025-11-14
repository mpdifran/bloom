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
  case onboardingPaywall = "onboarding_paywall"
  case onboardingFeaturePitch = "onboarding_feature_pitch"

  var name: String {
    switch self {
    case .onboardingPaywall:
      return "Onboarding Paywall"
    case .onboardingFeaturePitch:
      return "Onboarding Feature Pitch"
    }
  }

  var id: ExperimentIdentifier {
    ExperimentIdentifier(self.rawValue)
  }
}

extension ExperimentIdentifier {
  static let onboardingPaywall = Experiment.onboardingPaywall.id
  static let onboardingFeaturePitch = Experiment.onboardingFeaturePitch.id
}
