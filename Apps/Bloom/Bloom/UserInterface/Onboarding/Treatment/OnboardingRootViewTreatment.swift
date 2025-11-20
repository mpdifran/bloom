//
//  OnboardingRootViewTreatment.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-19.
//

import SwiftUI

extension OnboardingRootViewTreatment {
  enum Step: CaseIterable {
    case warmOpening
    case finish
  }
}

struct OnboardingRootViewTreatment: View {
  let onComplete: (Bool) -> Void

  @State private var step = Step.warmOpening

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Group {
      switch step {
      case .warmOpening:
        OnboardingWarmOpeningView {
          setStep(.finish)
        }
      case .finish:
        EmptyView()
      }
    }
    .animation(.easeInOut(duration: 1), value: step)
    .presentationCompactAdaptation(.fullScreenCover)
    .overlay {
      ContrastingPillLabel("Step 1 of 5")
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
    OnboardingRootViewTreatment() { (_) in }
  }
}
