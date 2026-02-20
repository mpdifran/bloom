//
//  OnboardingRootViewTreatment.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-19.
//

import SwiftUI
import CoreHealth

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
    case rating
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
      case .rating: return 7
      case .login: return 8
      case .finish: return nil
      }
    }

    static let stepCount = 8
  }
}

struct OnboardingRootViewTreatment: View {
  let onComplete: () -> Void

  @AppStorage("OnboardingRootViewTreatment.currentStep") private var currentStepRawValue = Step.warmOpening.rawValue
  @AppStorage("OnboardingRootViewTreatment.wasYesInWarmingStep") private var wasYesInWarmingStep = false
  @AppStorage("OnboardingRootViewTreatment.personalizationFocus") private var personalizationFocusRawValue: String?

  @ObservedObject private var healthManager = HealthManager.shared

  @Environment(\.dismiss) private var dismiss

  var step: Step {
    Step(rawValue: currentStepRawValue) ?? .warmOpening
  }

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
          self.personalizationFocusRawValue = focus?.rawValue
          setStep(.trust)
        }
      case .trust:
        OnboardingTrustView {
          setStep(.healthKit)
        }
      case .healthKit:
        OnboardingHealthKitTreatmentView(focus: PersonalizationFocus(rawValue: personalizationFocusRawValue ?? "")) {
          await healthManager.syncPersonalDataFromHealthKit()
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
          setStep(.rating)
        }
      case .rating:
        OnboardingRatingView {
          setStep(.login)
        }
      case .login:
        OnboardingLoginView {
          setStep(.finish)
        }
      case .finish:
        OnboardingFinishView {
          clearSavedState()
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
      self.currentStepRawValue = step.rawValue
    }
  }

  func clearSavedState() {
    currentStepRawValue = Step.warmOpening.rawValue
    wasYesInWarmingStep = false
    personalizationFocusRawValue = nil
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingRootViewTreatment() { }
  }
}
