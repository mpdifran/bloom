//
//  OnboardingHealthGoalView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-13.
//

import SFSafeSymbols
import SwiftUI
import AppUI
import HealthKit
import TelemetryDeck
import CoreHealth

struct OnboardingHealthGoalView: View {
  let onContinue: () -> Void

  @ObservedObject private var healthManager = HealthManager.shared

  @State private var index = 1
  @State private var didContinue = false
  @State private var currentWeight: HKQuantity?

  @State private var presentedSheet: AnyView?

  @FocusState private var isFocused: Bool

  private let suggestions = [
    "Be Healthy",
    "Lose Weight",
    "Get Stronger",
    "Have More Energy",
    "Be More Active",
    "Improve Sleep"
  ]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        BudImage(.budSalad)

        Group {
          Text("Let's talk about your goals.")
            .transition(.opacity)
            .appear(with: 1, currentIndex: index)

          Text("Where would you like to focus your efforts?")
            .transition(.opacity)
            .appear(with: 2, currentIndex: index)
        }
        .onboardingTextStyle()

        goalTextFieldView
          .transition(.blurReplace)
          .appear(with: 3, currentIndex: index)
      }
      .horizontalAlignment(.leading)
      .padding()
    }
    .groupedBackground()
    .sheet($presentedSheet)
    .animation(.default, value: index)
    .animation(.default, value: healthManager.focus)
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.selection, trigger: healthManager.focus)
    .sensoryFeedback(.selection, trigger: didContinue)
    .shelf(includePadding: false) {
      if index >= 3 {
        VStack(spacing: 16) {
          healthGoalSuggestionsView

          Button("Looks good") {
            didContinue.toggle()
            onContinue()
          }
          .buttonStyle(.onboarding)
          .disabled(!canContinue)
          .padding(.horizontal)
        }
        .padding(.vertical)
      }
    }
    .animation(.easeInOut, value: healthManager.focus)
    .task {
      while index < 3 {
        await advanceIndex()
      }
    }
    .onAppear {
      isFocused = true
      TelemetryDeck.signal("OB Health Goals")
    }
  }
}

private extension OnboardingHealthGoalView {

  var goalTextFieldView: some View {
    TextField(
      "",
      text: $healthManager.focus,
      prompt: Text("Describe your health focus"),
      axis: .vertical
    )
    .multilineTextAlignment(.center)
    .font(.title2)
    .fontDesign(.rounded)
    .bold()
    .cardContainer()
    .focused($isFocused)
    .contentTransition(.numericText())
  }

var healthGoalSuggestionsView: some View {
  ScrollViewReader { scrollProxy in
    ScrollView(.horizontal) {
      HStack {
        ForEach(suggestions, id: \.self) { suggestion in
          Text(suggestion)
            .font(.body)
            .bold()
            .fontDesign(.rounded)
            .lineLimit(1)
            .cardContainer(fill: healthManager.focus == suggestion
                           ? AnyShapeStyle(Color.accentColor)
                           : AnyShapeStyle(.background.secondary))
            .fixedSize(horizontal: true, vertical: false)
            .foregroundColor(healthManager.focus == suggestion ? .white : .primary)
            .onTapGesture {
              withAnimation {
                healthManager.focus = suggestion
                scrollProxy.scrollTo(suggestion, anchor: .center)
              }
            }
            .id(suggestion)
        }
      }
      .padding(.horizontal)
    }
    .scrollIndicators(.never)
  }
}

  var goalPickerView: some View {
    VStack {
      OnboardingHealthGoalCell(
        title: "Just Monitor My Health",
        symbol: .heartTextSquare,
        isSelected: healthManager.focus == "Monitor My Health"
      )
      .onTapGesture {
        healthManager.focus = "Monitor My Health"
      }

      Divider()

      OnboardingHealthGoalCell(
        title: "Lose Weight",
        symbol: .gaugeWithDotsNeedle0percent,
        isSelected: healthManager.focus == "Lose Weight"
      )
      .onTapGesture {
        healthManager.focus = "Lose Weight"
      }

      Divider()

      OnboardingHealthGoalCell(
        title: "Maintain Weight",
        symbol: .gaugeWithDotsNeedleBottom50percent,
        isSelected: healthManager.focus == "Maintain Weight"
      )
      .onTapGesture {
        healthManager.focus = "Maintain Weight"
      }

      Divider()

      OnboardingHealthGoalCell(
        title: "Gain Weight",
        symbol: .gaugeWithDotsNeedleBottom100percent,
        isSelected: healthManager.focus == "Gain Weight"
      )
      .onTapGesture {
        healthManager.focus = "Gain Weight"
      }
    }
    .cardContainer(fill: .background.secondary)
  }


  var targetWeightView: some View {
    VStack(alignment: .leading) {
      VStack(spacing: 16) {
        LabeledContent("Target Weight") {
          HStack {
            Text("\(targetWeight.displayString(for: .pound()))")
            Image(systemSymbol: .chevronUpChevronDown)
          }
          .font(.title3)
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
        }
        .bold()
        .selectable()
        .onTapGesture {
          presentedSheet = TargetWeightEditCard().asAny
        }
      }
      .cardContainer(fill: .background.secondary)
    }
  }

  var targetWeight: HKQuantity {
    HKQuantity(unit: .pound(), doubleValue: healthManager.targetWeight)
  }

  func advanceIndex() async {
    await Delay(1700)

    index += 1
  }

  var canContinue: Bool {
    return true
  }
}

struct OnboardingHealthGoalCell: View {
  let title: String
  let symbol: SFSymbol
  let isSelected: Bool

  var body: some View {
    HStack {
      Image(systemSymbol: symbol)
        .foregroundStyle(.text, .tint)
        .font(.title3)
        .bold()

      Text(title)
        .bold()

      Spacer()

      if isSelected {
        Image(systemSymbol: .checkmarkCircleFill)
          .foregroundStyle(.white, .tint)
          .font(.title3)
          .contentTransition(.symbolEffect)
      }
    }
    .padding(.vertical, 8)
    .selectable()
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingHealthGoalView { }
  }
}
