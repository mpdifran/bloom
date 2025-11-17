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
    case todayExplanation
    case nutritionExplanation
    case chatExplanation
    case bioAgeExplanation
    case healthKit
    case ageAndSex
    case focusArea
    case goalSetup
    case notifications
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

  private let vitalsViewModel = VitalsViewModel.shared

  @ObservedObject private var healthManager = HealthManager.shared

  @Environment(ExperimentManager.self) private var experimentManager
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Group {
      switch step {
      case .welcome:
        OnboardingWelcomeView {
          switch experimentManager.variant(for: .onboardingFeaturePitch) {
          case .treatment:
            setStep(.todayExplanation)
          case .control:
            setStep(.appExplanation)
          }
        }
      case .appExplanation:
        OnboardingAppExplanationView {
          setStep(.healthKit)
        }
        .onAppear {
          TelemetryDeck.signal("AB: Onboarding Feature Pitch - Control")
        }
      case .todayExplanation:
        OnboardingExplanationTodayInsightsView {
          setStep(.nutritionExplanation)
        }
        .onAppear {
          TelemetryDeck.signal("AB: Onboarding Feature Pitch - Treatment")
        }
      case .nutritionExplanation:
        OnboardingExplanationNutritionView {
          setStep(.chatExplanation)
        }
      case .chatExplanation:
        OnboardingExplanationChatView {
          setStep(.bioAgeExplanation)
        }
      case .bioAgeExplanation:
        OnboardingExplanationBioAgeView {
          setStep(.healthKit)
        }
      case .healthKit:
        switch experimentManager.variant(for: .onboardingFeaturePitch) {
        case .treatment:
          OnboardingHealthKitTreatmentView {
            checkHealthDataAndProceed()
          }
        case .control:
          OnboardingHealthKitView {
            checkHealthDataAndProceed()
          }
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
    .overlay {
      ProgressBar(value: self.step.progress, target: 1)
        .zStackAlignment(.top)
        .frame(width: 80)
    }
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
    
    // Check if all required health data is present (height is now optional)
    let hasAllHealthData = sex != nil && age != nil && sexName != nil
    
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
