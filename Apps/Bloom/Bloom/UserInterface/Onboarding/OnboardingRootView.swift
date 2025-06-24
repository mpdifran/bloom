//
//  OnboardingRootView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI
import CoreHealth

extension OnboardingRootView {
  enum Step {
    case welcome
    case appExplanation
    case healthKit
    case ageAndSex
    case focusArea
    case goalSetup
    case notifications
    case finish
  }
}

struct OnboardingRootView: View {
  let onComplete: () -> Void

  @State private var step = Step.welcome

  private let vitalsViewModel = VitalsViewModel.shared

  @ObservedObject private var healthManager = HealthManager.shared

  @AppStorage(.FeatureFlag.legacyGoalSetting) private var legacyGoalSetting = false

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Group {
      switch step {
      case .welcome:
        OnboardingWelcomeView {
          setStep(.appExplanation)
        }
      case .appExplanation:
        OnboardingAppExplanationView {
          setStep(.healthKit)
        }
      case .healthKit:
        OnboardingHealthKitView {
          setStep(.ageAndSex)
        }
      case .ageAndSex:
        OnboardingHealthAgeSexHeightView {
          setStep(.focusArea)
        }
      case .focusArea:
        OnboardingFocusAreaView {
          setStep(.notifications)
        }
      case .goalSetup:
        // TODO: This is incomplete
        OnboardingGoalSetupView {
          setStep(.notifications)
        }
      case .notifications:
        OnboardingNotificationPermissionView {
          setStep(.finish)
        }
      case .finish:
        OnboardingFinishView {
          onComplete()
        }
      }
    }
    .animation(.easeInOut(duration: 1), value: step)
    .presentationCompactAdaptation(.fullScreenCover)
  }
}

private extension OnboardingRootView {

  func setStep(_ step: Step) {
    withAnimation {
      self.step = step
    }
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingRootView() { }
  }
}
