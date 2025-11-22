//
//  OnboardingPersonalizationView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-19.
//

import SwiftUI
import AppUI
import BloomUI
import BloomModel
import BloomFoundation
import TelemetryDeck
import CoreHealth
import SFSafeSymbols

enum PersonalizationFocus {
  case understandHealthData
  case boostEnergyLevels
  case improveSleep
  case buildHealthyHabits
  case reduceStress
  case improveBodyComposition
  case custom
}

struct FocusPair: Identifiable {
  let symbol: SFSymbol
  let title: String
  let color: Color
  let focus: PersonalizationFocus

  var id: String { title }
}

struct OnboardingPersonalizationView: View {
  let isYes: Bool
  let onContinue: (PersonalizationFocus?) -> Void

  @ObservedObject private var healthManager = HealthManager.shared

  @State private var customGoal = ""
  @State private var selectionToggle = false
  @State private var index = 0

  @FocusState private var isFocused: Bool

  private let suggestions = [
    FocusPair(
      symbol: .heartFill,
      title: "Understand my health data",
      color: .mutedPink,
      focus: .understandHealthData
    ),
    FocusPair(
      symbol: .battery100percentBolt,
      title: "Boost energy levels",
      color: .mutedOrange,
      focus: .boostEnergyLevels
    ),
    FocusPair(
      symbol: .moonZzzFill,
      title: "Improve sleep",
      color: .mutedIndigo,
      focus: .improveSleep
    ),
    FocusPair(
      symbol: .figureRun,
      title: "Build healthier habits",
      color: .mutedGreen,
      focus: .buildHealthyHabits
    ),
    FocusPair(
      symbol: .boltFill,
      title: "Reduce stress",
      color: .mutedYellow,
      focus: .reduceStress
    ),
    FocusPair(
      symbol: .gaugeWithDotsNeedle33percent,
      title: "Improve my body composition",
      color: .mutedBlue,
      focus: .improveBodyComposition
    )
  ]

  var body: some View {
    BloomScrollView(showsChatBar: false, padding: .bottom) {
      ZStack {
        Image(.afternoonScenery)
          .resizable()
          .scaledToFit()
          .offset(y: -40)
          .parallaxOverscroll()
          .zStackAlignment(.top)

        VStack(alignment: .leading) {
          BudImage(.budCoach, dimension: 200)
            .horizontallyCentered()

          discussionSection
        }
        .horizontalAlignment(.leading)
        .padding(.top, 100)
      }
    }
    .shelf(isVisible: isFocused) {
      Button {
        if customGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          isFocused = false
        } else {
          selectionToggle.toggle()
          Task {
            await Delay(800)
            onContinue(nil)
          }
        }
      } label: {
        Text("Continue")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    }
    .onAppear {
      healthManager.focus = ""
      TelemetryDeck.signal("OB Personalization")
    }
    .animation(.default, value: healthManager.focus)
    .animation(.default, value: index)
    .sensoryFeedback(.impact, trigger: index)
    .sensoryFeedback(.success, trigger: selectionToggle)
    .task {
      await advanceIndex()
    }
  }
}

private extension OnboardingPersonalizationView {

  func advanceIndex() async {
    await Delay(500)
    index += 1
    await Delay(800)
    index += 1
    await Delay(800)
    index += 1
    await Delay(800)
    index += 1
    await Delay(100)
    index += 1
    await Delay(200)
    index += 1
    await Delay(100)
    index += 1
    await Delay(200)
    index += 1
    await Delay(100)
    index += 1
    await Delay(200)
    index += 1
  }
}

private extension OnboardingPersonalizationView {

  @ViewBuilder
  var discussionSection: some View {
    if index >= 1 {
      Text(isYes ? "Awesome!" : "Can do!")
        .primaryOnboardingTextStyle()
        .transition(.blurReplace)
        .padding(.horizontal)
        .fixedSize(horizontal: false, vertical: true)
    }

    if index >= 2 {
      ChatBubble(
        position: .leading,
        showTail: true,
        backgroundStyle: .background
      ) {
        Text(isYes ? "Let's make Bloom work perfectly for you." : "I show you what’s affecting your health and what you can do about it.")
          .secondaryOnboardingTextStyle()
          .fixedSize(horizontal: false, vertical: true)
      }
      .transition(.move(edge: .leading))
    }

    if index >= 3 {
      ChatBubble(
        position: .leading,
        showTail: true,
        backgroundStyle: .background
      ) {
        Text("What do you want me to help you with?")
          .secondaryOnboardingTextStyle()
          .fixedSize(horizontal: false, vertical: true)
      }
      .transition(.move(edge: .leading))
    }

    focusAreaSection

    if index >= 7 {
      textInputSection
        .transition(.blurReplace)
    }
  }

  var focusAreaSection: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 400), spacing: 12)], spacing: 12) {
      ForEachEnumerated(suggestions) { (index, suggestion) in
        if canShowFocusCard(for: index) {
          FocusCardCell(
            title: suggestion.title,
            symbol: suggestion.symbol,
            isSelected: healthManager.focus == suggestion.title
          )
          .transition(.move(edge: index % 2 == 0 ? .leading : .trailing))
          .tint(suggestion.color)
          .onTapGesture {
            healthManager.focus = suggestion.title
            selectionToggle.toggle()

            Task {
              await Delay(800)
              onContinue(suggestion.focus)
            }
          }
        }
      }
    }
    .padding(.horizontal)
    .padding(.top)
  }

  func canShowFocusCard(for focusCardIndex: Int) -> Bool {
    index >= focusCardIndex + 4
  }

  var textInputSection: some View {
    HStack {
      Image(systemSymbol: .sparkles)
        .font(.title2)
        .foregroundStyle(.mutedLightBlue)

      TextField(
        "",
        text: $customGoal,
        prompt: Text("Something else..."),
        axis: .vertical
      )
    }
    .multilineTextAlignment(.leading)
    .textInputAutocapitalization(.sentences)
    .secondaryOnboardingTextStyle()
    .cardContainer()
    .focused($isFocused)
    .contentTransition(.numericText())
    .padding(.horizontal)
    .onChange(of: customGoal) { oldValue, newValue in
      healthManager.focus = newValue
    }
  }
}

private struct FocusCardCell: View {
  let title: String
  let symbol: SFSymbol
  let isSelected: Bool

  var body: some View {
    VStack {
      Image(systemSymbol: symbol)
        .font(.title2)
        .bold()
        .foregroundStyle(isSelected ? AnyShapeStyle(.black) : AnyShapeStyle(.tint))
        .horizontalAlignment(.leading)

      Spacer(minLength: 20)

      Text(title)
        .font(.headline)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(isSelected ? .black : .text)
        .horizontalAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }
    .cardContainer(fill: isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.background))
  }
}

#Preview("Yes") {
  PreviewEnvironment {
    OnboardingPersonalizationView(isYes: true) { (_) in }
  }
}

#Preview("No") {
  PreviewEnvironment {
    OnboardingPersonalizationView(isYes: false) { (_) in }
  }
}

