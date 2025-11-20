//
//  OnboardingRootViewTreatment.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-19.
//

import SwiftUI

extension OnboardingRootViewTreatment {
  enum Step: Int, CaseIterable {
    case warmOpening
    case personalization
    case finish
  }
}

struct OnboardingRootViewTreatment: View {
  let onComplete: () -> Void

  @State private var step = Step.warmOpening
  @State private var wasYesInWarmingStep = false

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Group {
      switch step {
      case .warmOpening:
        OnboardingWarmOpeningView { (wasYes) in
          wasYesInWarmingStep = wasYes
          setStep(.personalization)
        }
      case .personalization:
        OnboardingPersonalizationView(isYes: wasYesInWarmingStep) {
          setStep(.finish)
        }
      case .finish:
        Text("End")
      }
    }
    .animation(.easeInOut(duration: 1), value: step)
    .presentationCompactAdaptation(.fullScreenCover)
    .overlay {
      ContrastingPillLabel("Step \(step.rawValue + 1) of \(Step.allCases.count)")
        .zStackAlignment(.top)
    }
  }
}

private extension OnboardingRootViewTreatment {

  func setStep(_ step: Step) {
    withAnimation {
      self.step = step
    }
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingRootViewTreatment() { }
  }
}
