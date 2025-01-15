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
  @State private var isHealthDataCorrect: Bool?
  @State private var didContinue = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        if
          let sex = healthManager.healthStore.sex(),
          let age = healthManager.healthStore.age(),
          let sexName = sex.personName,
          healthManager.heightCM > 0
        {
          hasHealthDataContent(age: age, sex: sexName, height: healthManager.height())

          if isHealthDataCorrect == false {
            ageSexHeightPicker
              .appear(with: 4, currentIndex: index)
          } else if isHealthDataCorrect == true {
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
    .topSafeAreaBlur()
    .animation(.default, value: index)
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.selection, trigger: isHealthDataCorrect)
    .sensoryFeedback(.selection, trigger: didContinue)
    .task {
      while index < 3 {
        await advanceIndex()
      }
    }
    .shelf {
      if canShowContinueButton {
        VStack {
          if healthManager.age() < 1 {
            Text("You must be at least 1 years old to use Bloom.")
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
          .disabled(healthManager.age() < 1)
        }
      }
    }
    .onAppear {
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

  var canShowContinueButton: Bool {
    let sex = healthManager.healthStore.sex()
    let age = healthManager.healthStore.age()

    let hasHealthData = sex != nil && age != nil && isHealthDataCorrect != nil
    let hasNoHealthData = (sex == nil || age == nil) && index >= 3

    return hasHealthData || hasNoHealthData
  }

  @ViewBuilder
  func hasHealthDataContent(age: Int, sex: String, height: HKQuantity) -> some View {
    Text("Looks Great!")
      .appear(with: 1, currentIndex: index)

    Text("According to your Health data, you're a \(age) year old \(sex). Your height is \(height.displayString(for: .meterUnit(with: .centi))). Is that correct?")
      .appear(with: 2, currentIndex: index)

    HStack {
      Button("Yes") {
        isHealthDataCorrect = true
        index = 4
      }
      .buttonStyle(.onboarding)
      .opacity(isHealthDataCorrect == false ? 0.3 : 1)

      Spacer(minLength: 20)

      Button("No") {
        isHealthDataCorrect = false
        index = 4
      }
      .buttonStyle(.onboarding)
      .opacity(isHealthDataCorrect == true ? 0.3 : 1)
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
