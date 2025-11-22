//
//  OnboardingUserDetailsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-21.
//

import SwiftUI
import BloomUI
import CoreHealth
import BloomFoundation
import TelemetryDeck
import HealthKit

struct OnboardingUserDetailsView: View {
  let onContinue: () -> Void

  @State private var age: Int = 0
  @State private var index = 0
  @State private var onContinueToggle = false

  @FocusState private var isFocused: Bool
  @FocusState private var isAgeFocused: Bool

  @ObservedObject private var healthManager = HealthManager.shared

  var body: some View {
    BloomScrollView(showsChatBar: false, padding: .vertical) {
      VStack(alignment: .leading) {
        if index >= 1{
          BudImage(.budThinking, dimension: 120)
            .transition(.scale)
            .padding(.horizontal)
        }

        contentSection
      }
      .horizontalAlignment(.leading)
    }
    .animation(.default, value: index)
    .animation(.default, value: cannotContinue)
    .sensoryFeedback(.impact, trigger: index)
    .shelf(isVisible: index >= 4) {
      if isAgeFocused || isFocused {
        Button {
          isFocused = false
          isAgeFocused = false
        } label: {
          Text("Done")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
      } else {
        if let statusText {
          Text(statusText)
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }

        Button {
          onContinueToggle.toggle()
          onContinue()
        } label: {
          Text("Continue")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .disabled(cannotContinue)
      }
    }
    .task {
      await advanceIndex()
    }
    .onAppear {
      TelemetryDeck.signal("OB User Details")
    }
    .onChange(of: age) { _, newAge in
      guard newAge > 0 else { return }
      let currentYear = Calendar.current.component(.year, from: .now)
      healthManager.birthYear = currentYear - newAge
    }
  }
}

private extension OnboardingUserDetailsView {

  func advanceIndex() async {
    await Delay(500)
    index += 1
    await Delay(800)
    index += 1
    await Delay(500)
    index += 1
    await Delay(500)
    withAnimation {
      index += 1
    }
  }

  var cannotContinue: Bool {
    age < 18
  }

  var statusText: String? {
    if age < 18 {
      return "You must be at least 18 years old to use Bloom."
    }
    return nil
  }
}

private extension OnboardingUserDetailsView {

  @ViewBuilder
  var contentSection: some View {
    if index >= 1 {
      Text("Tell me a bit about you")
        .primaryOnboardingTextStyle()
        .padding(.horizontal)
        .transition(.move(edge: .leading))

      Text("This helps me personalize your insights and make sure Bloom is the right fit.")
        .padding(.horizontal)
        .secondaryOnboardingTextStyle()
        .foregroundStyle(.secondary)
        .transition(.move(edge: .leading))
    }

    if index >= 2 {
      EditUserProfileCardView()
        .padding(.horizontal)
        .focused($isFocused)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    if index >= 3 {
      VStack {
        LabeledContent("Age") {
          TextField("", value: $age, formatter: NumberFormatter.noDecimalPlaces)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.trailing)
            .frame(width: 70)
            .fontDesign(.rounded)
            .keyboardType(.numberPad)
            .focused($isAgeFocused)
            .selectAllTextOnBeginEditing()
        }
        .bold()
        .frame(height: 40)

        Divider()

        LabeledContent("Sex") {
          Picker("", selection: $healthManager.sexKind) {
            ForEach(HKBiologicalSex.allCases, id: \.self) { sex in
              Text(sex.name)
                .tag(sex)
            }
          }
        }
        .bold()
        .frame(height: 40)
      }
      .cardContainer()
      .padding(.horizontal)
      .transition(.move(edge: .bottom).combined(with: .opacity))
    }
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingUserDetailsView() { }
  }
}
