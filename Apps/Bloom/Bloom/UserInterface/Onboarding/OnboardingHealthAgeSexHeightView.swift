//
//  OnboardingHealthAgeSexHeightView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-15.
//

import SwiftUI
import AppUI
import HealthKitUI
import TelemetryDeck
import CoreHealth

@MainActor
struct OnboardingHealthAgeSexHeightView: View {
  let onContinue: () -> Void

  @ObservedObject private var healthManager = HealthManager.shared

  @Bindable private var unitPreferences = HealthUnitPreferences.shared

  @State private var index = 1
  /// The user has confirmed the health data provided is correct. If the health data was populated, the user must confirm to continue.
  @State private var isHealthDataConfirmed: Bool?
  /// Set when the view appears if the user was missing health data.
  @State private var wasMissingHealthData: Bool = false
  @State private var didContinue = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        if wasMissingHealthData {
          doesNotHaveHealthDataContent

          ageSexHeightPicker
            .appear(with: 3, currentIndex: index)
        } else {
          hasHealthDataContent(
            age: healthManager.age(),
            sex: healthManager.isFemale ? "female" : "male",
            height: healthManager.height()
          )

          if isHealthDataConfirmed == false {
            ageSexHeightPicker
              .appear(with: 4, currentIndex: index)
          } else {
            Text("Glad to get to know you better!")
              .appear(with: 4, currentIndex: index, secondaryIfNotCurrentIndex: false)
          }
        }
      }
      .horizontalAlignment(.leading)
      .padding()
      .onboardingTextStyle()
    }
    .groupedBackground()
    .animation(.default, value: index)
    .animation(.default, value: healthManager.birthday)
    .animation(.default, value: healthManager.heightCM)
    .animation(.default, value: healthManager.isFemale)
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.selection, trigger: isHealthDataConfirmed)
    .sensoryFeedback(.selection, trigger: didContinue)
    .task {
      while index < 3 {
        await advanceIndex()
      }
    }
    .shelf {
      if index >= 3 {
        VStack {
          if healthManager.age() < 1 {
            Text("You must be at least 1 year old to use Bloom.")
              .font(.subheadline)
              .fontDesign(.rounded)
              .bold()
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
          } else if healthManager.heightCM < 1 {
            Text("Please enter a valid height.")
              .font(.subheadline)
              .fontDesign(.rounded)
              .bold()
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
          }
          Button("Continue") {
            didContinue.toggle()
            onContinue()
            TelemetryDeck.stopAndSendDurationSignal("OB Age+Sex Duration")
          }
          .buttonStyle(.onboarding)
          .disabled(shouldDisableContinue)
        }
      }
    }
    .onAppear {
      if !isHealthKitDataValid {
        wasMissingHealthData = true
        TelemetryDeck.signal(
          "OB Age+Sex - Health Data Check",
          parameters: [
            "sex": healthManager.healthStore.sex()?.personName == nil ? "Not Present" : "Present",
            "age": healthManager.healthStore.age() == nil ? "Not Present" : "Present",
            "height": healthManager.heightCM > 0 ? "Not Present" : "Present",
            "isMissingHealthData": "yes"
          ]
        )
      } else {
        TelemetryDeck.signal(
          "OB Age+Sex - Health Data Check",
          parameters: [
            "sex": healthManager.healthStore.sex()?.personName == nil ? "Not Present" : "Present",
            "age": healthManager.healthStore.age() == nil ? "Not Present" : "Present",
            "height": healthManager.heightCM > 0 ? "Not Present" : "Present",
            "isMissingHealthData": "no"
          ]
        )
      }
      healthManager.birthday = healthManager.healthStore.birthday() ?? Date()
      healthManager.isFemale = healthManager.healthStore.sex() == .female

      TelemetryDeck.signal("OB Age+Sex")
      TelemetryDeck.startDurationSignal("OB Age+Sex Duration")
    }
  }
}

private extension OnboardingHealthAgeSexHeightView {

  var shouldDisableContinue: Bool {
    if wasMissingHealthData {
      return !hasValidHealthData
    }

    return !hasValidHealthData || isHealthDataConfirmed == nil
  }

  func advanceIndex() async {
    await Delay(1000)

    index += 1
  }

  var isHealthKitDataValid: Bool {
    let sex = healthManager.healthStore.sex()
    let age = healthManager.healthStore.age()
    let sexName = sex?.personName
    let height = healthManager.heightCM

    return sex != nil && age != nil && sexName != nil && height > 0
  }

  var hasValidHealthData: Bool {
    let age = healthManager.age()
    let height = healthManager.heightCM

    return age >= 1 && height > 0
  }

  @ViewBuilder
  func hasHealthDataContent(age: Int, sex: String, height: HKQuantity) -> some View {
    BudImage(.budWorkout)

    Text("Looks Great!")
      .appear(with: 1, currentIndex: index, secondaryIfNotCurrentIndex: false)

    Text("According to your Health data, you're a \(age) year old \(sex). Your height is \(height.displayString(for: .meterUnit(with: .centi))). Does that look right?")
      .contentTransition(.numericText())
      .appear(with: 2, currentIndex: index, secondaryIfNotCurrentIndex: false)

    HStack {
      Button("Yes") {
        isHealthDataConfirmed = true
        index = 4
        TelemetryDeck.signal(
          "OB Age+Sex - Confirmation",
          parameters: ["health-data-confirmation": "yes"]
        )
      }
      .buttonStyle(.onboarding)
      .opacity(isHealthDataConfirmed == false ? 0.3 : 1)

      Spacer(minLength: 20)

      Button("No") {
        isHealthDataConfirmed = false
        index = 4
        TelemetryDeck.signal(
          "OB Age+Sex - Confirmation",
          parameters: ["health-data-confirmation": "no"]
        )
      }
      .buttonStyle(.onboarding)
      .opacity(isHealthDataConfirmed == true ? 0.3 : 1)
    }
    .appear(with: 3, currentIndex: index)
  }

  @ViewBuilder
  var doesNotHaveHealthDataContent: some View {
    BudImage(.budSadWorkout)

    Text("Uh oh, looks like I wasn't able to get some important information.")
      .appear(with: 1, currentIndex: index, secondaryIfNotCurrentIndex: false)
    Text("Do you mind providing it?")
      .appear(with: 2, currentIndex: index, secondaryIfNotCurrentIndex: false)
  }

  var ageSexHeightPicker: some View {
    VStack {
      VStack {
        LabeledContent("Birthday") {
          DatePicker(
            "",
            selection: $healthManager.birthday,
            in: ...Date(),
            displayedComponents: .date
          )
        }
        
        Divider()
        
        LabeledContent("Sex") {
          Picker("", selection: $healthManager.isFemale) {
            Text("Male")
              .tag(false)
            Text("Female")
              .tag(true)
          }
          .pickerStyle(.segmented)
          .frame(width: 150, height: 50)
        }
        
        Divider()
        
        LabeledContent("Height") {
          HeightEditorTextField()
        }
      }
      .cardContainer(fill: .background.secondary)
      .transition(.blurReplace)
    }
    .font(.body)
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingHealthAgeSexHeightView { }
  }
}
