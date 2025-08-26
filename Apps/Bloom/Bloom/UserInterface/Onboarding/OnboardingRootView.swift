//
//  OnboardingRootView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI
import CoreHealth
import TelemetryDeck

extension OnboardingRootView {
  enum Step {
    case welcome
    case appExplanation
    case healthKit
    case ageAndSex
    case focusArea
    case goalSetup
    case notifications
    case login
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
          checkHealthDataAndProceed()
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

  func checkHealthDataAndProceed() {
    // Check if we already have complete health data from HealthKit
    let sex = healthManager.healthStore.sex()
    let age = healthManager.healthStore.age()
    let sexName = sex?.personName
    let height = healthManager.heightCM
    
    // Check if all health data is present
    let hasAllHealthData = sex != nil && age != nil && sexName != nil && height > 0
    
    // Also check if user is 18 or older (if age is available)
    let isAgeValid = (age ?? 1) >= 18
    
    let isHealthKitDataValid = hasAllHealthData && isAgeValid
    
    if isHealthKitDataValid {
      // Skip the age/sex screen and go directly to focus area
      // Make sure to set the health data values
      healthManager.birthday = healthManager.healthStore.birthday() ?? Date()
      healthManager.isFemale = healthManager.healthStore.sex() == .female
      
      setStep(.focusArea)
    } else {
      // Need to collect age/sex data
      // This includes cases where user is under 18 and needs to verify/correct their age
      setStep(.ageAndSex)
    }
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingRootView() { }
  }
}
