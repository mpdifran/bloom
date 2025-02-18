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

@MainActor
struct OnboardingHealthAgeSexHeightView: View {
  let onContinue: () -> Void

  @ObservedObject private var healthManager = HealthManager.shared

  @Bindable private var unitPreferences = HealthUnitPreferences.shared

  @State private var index = 1
  /// The user has confirmed the health data provided is correct. If the health data was populated, the user must confirm to continue.
  @State private var isHealthDataConfirmed: Bool = false
  /// Set when the view appears if the user was missing health data.
  @State private var wasMissingHealthData: Bool = false
  @State private var didContinue = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        if
          let sex = healthManager.healthStore.sex(),
          let age = healthManager.healthStore.age(),
          let sexName = sex.personName,
          !wasMissingHealthData
        {
          hasHealthDataContent(age: age, sex: sexName, height: healthManager.height())

          if !isHealthDataConfirmed {
            ageSexHeightPicker
              .appear(with: 4, currentIndex: index)
          } else {
            Text("Glad to get to know you better!")
              .appear(with: 4, currentIndex: index)
          }
        } else {
          doesNotHaveHealthDataContent

          ageSexHeightPicker
            .appear(with: 3, currentIndex: index)
        }
      }
      .horizontalAlignment(.leading)
      .padding()
      .onboardingTextStyle()
    }
    .topSafeAreaFill(.background)
    .animation(.default, value: index)
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
            Text("You must be at least 1 years old to use Bloom.")
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
          }
          .buttonStyle(.onboarding)
          .disabled(!hasValidHealthData)
        }
      }
    }
    .onAppear {
      if !isHealthKitDataValid {
        wasMissingHealthData = true
      }
      healthManager.birthday = healthManager.healthStore.birthday() ?? Date()
      healthManager.isFemale = healthManager.healthStore.sex() == .female

      TelemetryDeck.signal("OB Age+Sex")
    }
  }
}

private extension OnboardingHealthAgeSexHeightView {

  func advanceIndex() async {
    await Delay(1700)

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

    return age > 1 && height > 0
  }

  @ViewBuilder
  func hasHealthDataContent(age: Int, sex: String, height: HKQuantity) -> some View {
    Text("Looks Great!")
      .appear(with: 1, currentIndex: index)

    Text("According to your Health data, you're a \(age) year old \(sex). Your height is \(height.displayString(for: .meterUnit(with: .centi))). Is that correct?")
      .appear(with: 2, currentIndex: index)

    HStack {
      Button("Yes") {
        isHealthDataConfirmed = true
        index = 4
      }
      .buttonStyle(.onboarding)
      .opacity(isHealthDataConfirmed == false ? 0.3 : 1)

      Spacer(minLength: 20)

      Button("No") {
        isHealthDataConfirmed = false
        index = 4
      }
      .buttonStyle(.onboarding)
      .opacity(isHealthDataConfirmed == true ? 0.3 : 1)
    }
    .appear(with: 3, currentIndex: index)
  }

  @ViewBuilder
  var doesNotHaveHealthDataContent: some View {
    Text("Uh oh, looks like I wasn't able to get some important information.")
      .appear(with: 1, currentIndex: index)
    Text("Do you mind providing it for me?")
      .appear(with: 2, currentIndex: index)
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
  OnboardingHealthAgeSexHeightView { }
}
