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

enum Experiment: String, CaseIterable {
  case onboardingPaywall = "onboarding_paywall"

  var name: String {
    switch self {
    case .onboardingPaywall:
      return "Onboarding Paywall"
    }
  }

  var id: ExperimentIdentifier {
    ExperimentIdentifier(self.rawValue)
  }
}

extension ExperimentIdentifier {
  static let onboardingPaywall = Experiment.onboardingPaywall.id
}
