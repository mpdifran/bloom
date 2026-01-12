//
//  OnboardingHealthAgeSexView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-15.
//

import SwiftUI
import AppUI
import TelemetryDeck
import CoreHealth
import BloomFoundation
import BloomUI
import HealthKit

@MainActor
struct OnboardingHealthAgeSexView: View {
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

          ageSexPicker
            .appear(with: 3, currentIndex: index)
        } else {
          hasHealthDataContent(
            age: healthManager.age(),
            sex: healthManager.sexKind == .female ? "female" : "male"
          )

          if isHealthDataConfirmed == false {
            ageSexPicker
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
    .animation(.default, value: healthManager.birthMonth)
    .animation(.default, value: healthManager.birthYear)
    .animation(.default, value: healthManager.heightCM)
    .animation(.default, value: healthManager.sexKind)
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
          if healthManager.age() < 18 {
            Text("You must be at least 18 years old to use Bloom.")
              .font(.subheadline)
              .fontDesign(.rounded)
              .bold()
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
          }
          Button {
            didContinue.toggle()
            onContinue()
            TelemetryDeck.stopAndSendDurationSignal("OB Age+Sex Duration")
          } label: {
            Text("Continue")
              .horizontallyCentered()
          }
          .buttonStyle(.primary)
          .disabled(shouldDisableContinue)
        }
      }
    }
    .onAppear {
      if let birthday = healthManager.healthStore.birthday() {
        let components = Calendar.current.dateComponents([.year, .month], from: birthday)
        if let year = components.year {
          healthManager.birthYear = year
        }
        if let month = components.month {
          healthManager.birthMonth = month
        }
      }
      if let sex = healthManager.healthStore.sex() {
        healthManager.sexKind = sex
      }

      TelemetryDeck.signal("OB Age+Sex")
      TelemetryDeck.startDurationSignal("OB Age+Sex Duration")
    }
  }
}

private extension OnboardingHealthAgeSexView {

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

    return sex != nil && age != nil
  }

  var hasValidHealthData: Bool {
    let age = healthManager.age()

    return age >= 18
  }

  @ViewBuilder
  func hasHealthDataContent(age: Int, sex: String) -> some View {
    BudImage(.budWorkout)

    Text("Looks Great!")
      .appear(with: 1, currentIndex: index, secondaryIfNotCurrentIndex: false)

    Text("According to your data, you're a \(age) year old \(sex). Does that look right?")
      .contentTransition(.numericText())
      .appear(with: 2, currentIndex: index, secondaryIfNotCurrentIndex: false)

    HStack {
      Button {
        isHealthDataConfirmed = true
        index = 4
        TelemetryDeck.signal(
          "OB Age+Sex - Confirmation",
          parameters: ["health-data-confirmation": "yes"]
        )
      } label: {
        Text("Yes")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
      .opacity(isHealthDataConfirmed == false ? 0.3 : 1)

      Spacer(minLength: 20)

      Button {
        isHealthDataConfirmed = false
        index = 4
        TelemetryDeck.signal(
          "OB Age+Sex - Confirmation",
          parameters: ["health-data-confirmation": "no"]
        )
      } label: {
        Text("No")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
      .opacity(isHealthDataConfirmed == true ? 0.3 : 1)
    }
    .appear(with: 3, currentIndex: index)
  }

  @ViewBuilder
  var doesNotHaveHealthDataContent: some View {
    BudImage(.budThinking)

    Text("Uh oh, looks like I wasn't able to get some important information.")
      .appear(with: 1, currentIndex: index, secondaryIfNotCurrentIndex: false)
    Text("Do you mind providing it?")
      .appear(with: 2, currentIndex: index, secondaryIfNotCurrentIndex: false)
  }

  var ageSexPicker: some View {
    VStack {
      VStack {
        LabeledContent("Birth Month (Optional)") {
          Picker("", selection: $healthManager.birthMonth) {
            Text("Not Set").tag(0)
            ForEach(1...12, id: \.self) { month in
              Text(Calendar.current.monthSymbols[month - 1]).tag(month)
            }
          }
          .pickerStyle(.menu)
        }

        Divider()

        LabeledContent("Birth Year") {
          Picker("", selection: $healthManager.birthYear) {
            ForEach((1924...Calendar.current.component(.year, from: .now)).reversed(), id: \.self) { year in
              Text(String(year))
                .tag(year)
            }
          }
          .pickerStyle(.menu)
        }

        Divider()

        LabeledContent("Sex") {
          Picker("", selection: $healthManager.sexKind) {
            ForEach(HKBiologicalSex.allCases, id: \.self) { sex in
              Text(sex.name)
                .tag(sex)
            }
          }
          .pickerStyle(.menu)
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
    OnboardingHealthAgeSexView { }
  }
}
