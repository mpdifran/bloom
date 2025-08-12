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
    case healthKitTreatment
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
          await advanceToHealthKitViewExperimentVariant()
        }
      case .healthKit:
        OnboardingHealthKitView {
          await checkHealthDataAndProceed()
        }
      case .healthKitTreatment:
        OnboardingHealthKitViewTreatement {
          await checkHealthDataAndProceed()
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
  
  func advanceToHealthKitViewExperimentVariant() async {
    let experimentId = String.ExperimentID.onboardingHealthKitView
    let variant = await ExperimentManager.shared.variant(for: experimentId)
    
    // Log variant assignment
    TelemetryDeck.signal("Experiment.Assigned", parameters: [
      "experiment_id": experimentId,
      "variant": variant.rawValue
    ])

    switch variant {
    case .control:
      setStep(.healthKit)
    case .treatment:
      setStep(.healthKitTreatment)
    }
  }

  func checkHealthDataAndProceed() async {
    // Check if we already have complete health data from HealthKit
    let sex = healthManager.healthStore.sex()
    let age = healthManager.healthStore.age()
    let sexName = sex?.personName
    let height = healthManager.heightCM
    
    let isHealthKitDataValid = sex != nil && age != nil && sexName != nil && height > 0
    
    if isHealthKitDataValid {
      // Skip the age/sex screen and go directly to focus area
      // Make sure to set the health data values
      healthManager.birthday = healthManager.healthStore.birthday() ?? Date()
      healthManager.isFemale = healthManager.healthStore.sex() == .female
      
      setStep(.focusArea)
    } else {
      // Need to collect age/sex data
      setStep(.ageAndSex)
    }
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingRootView() { }
  }
}
