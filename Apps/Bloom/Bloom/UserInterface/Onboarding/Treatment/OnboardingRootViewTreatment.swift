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
    case trust
    case healthKit
    case personalDetails
    case goalSetup
    case notifications
    case otherPermissions
    case login
    case finish

    var stepNumber: Int? {
      switch self {
      case .warmOpening: return 1
      case .personalization: return 2
      case .trust, .healthKit: return 3
      case .personalDetails: return 4
      case .goalSetup: return 5
      case .notifications, .otherPermissions: return 6
      case .login: return 7
      case .finish: return nil
      }
    }

    static let stepCount = 7
  }
}

struct OnboardingRootViewTreatment: View {
  let onComplete: () -> Void

  @State private var step = Step.warmOpening
  @State private var wasYesInWarmingStep = false
  @State private var personalizationFocus: PersonalizationFocus?

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
        OnboardingPersonalizationView(isYes: wasYesInWarmingStep) { (focus) in
          personalizationFocus = focus
          setStep(.trust)
        }
      case .trust:
        OnboardingTrustView {
          setStep(.healthKit)
        }
      case .healthKit:
        OnboardingHealthKitTreatmentView(focus: personalizationFocus) {
          setStep(.personalDetails)
        }
      case .personalDetails:
        OnboardingUserDetailsView {
          setStep(.goalSetup)
        }
      case .goalSetup:
        OnboardingGoalSetupView {
          setStep(.notifications)
        }
      case .notifications:
        OnboardingNotificationPermissionView {
          setStep(.otherPermissions)
        }
      case .otherPermissions:
        OnboardingCalendarWeatherView {
          setStep(.login)
        }
      case .login:
        OnboardingLoginView {
          setStep(.finish)
        }
      case .finish:
        OnboardingFinishView {
          onComplete()
        }
      }
    }
    .presentationCompactAdaptation(.fullScreenCover)
    .overlay {
      if let stepNumber = step.stepNumber {
        ContrastingPillLabel("Step \(stepNumber) of \(Step.stepCount)")
          .contentTransition(.numericText())
          .zStackAlignment(.top)
      }
    }
    .animation(.default, value: step)
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
