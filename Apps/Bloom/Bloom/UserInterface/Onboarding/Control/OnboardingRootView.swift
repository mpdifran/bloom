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
  enum Step: CaseIterable {
    case welcome
    case appExplanation
    case healthKit
    case ageAndSex
    case focusArea
    case goalSetup
    case notifications
    case otherPermissions
    case rating
    case login
    case finish
  }
}

extension OnboardingRootView.Step {
  var progress: Double {
    let count = Self.allCases.count
    return Double((Self.allCases.firstIndex(of: self) ?? 0) + 1) / Double(count)
  }
}

struct OnboardingRootView: View {
  let onComplete: () -> Void

  @State private var step = Step.welcome

  @ObservedObject private var healthManager = HealthManager.shared

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
//      case .todayExplanation:
//        OnboardingExplanationTodayInsightsView {
//          setStep(.nutritionExplanation)
//        }
//      case .nutritionExplanation:
//        OnboardingExplanationNutritionView {
//          setStep(.chatExplanation)
//        }
//      case .chatExplanation:
//        OnboardingExplanationChatView {
//          setStep(.bioAgeExplanation)
//        }
//      case .bioAgeExplanation:
//        OnboardingExplanationBioAgeView {
//          setStep(.healthKit)
//        }
      case .healthKit:
        OnboardingHealthKitView {
          checkHealthDataAndProceed()
        }
      case .ageAndSex:
        OnboardingHealthAgeSexView {
          setStep(.focusArea)
        }
      case .focusArea:
        OnboardingFocusAreaView {
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
    
    // Check if all required health data is present (height is now optional)
    let hasAllHealthData = sex != nil && age != nil
    
    // Also check if user is 18 or older (if age is available)
    let isAgeValid = (age ?? 1) >= 18
    
    let isHealthKitDataValid = hasAllHealthData && isAgeValid
    
    if isHealthKitDataValid {
      // Skip the age/sex screen and go directly to focus area
      // Make sure to set the health data values
      if let age = healthManager.healthStore.age() {
        let currentYear = Calendar.current.component(.year, from: .now)
        healthManager.birthYear = currentYear - age
      }
      if let sex = healthManager.healthStore.sex() {
        healthManager.sexKind = sex
      }

      setStep(.focusArea)
    } else {
      // Need to collect age/sex data
      // This includes cases where user is under 18 and needs to verify/correct their age
      setStep(.ageAndSex)
    }
  }
}

#Preview("Control") {
  PreviewEnvironment(variant: .control) {
    OnboardingRootView() { }
  }
}

#Preview("Treatment") {
  PreviewEnvironment(variant: .treatment) {
    OnboardingRootView() { }
  }
}
