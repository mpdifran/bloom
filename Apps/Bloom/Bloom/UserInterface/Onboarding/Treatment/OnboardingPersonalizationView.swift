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

struct FocusPair: Identifiable {
  let symbol: SFSymbol
  let title: String
  let color: Color

  var id: String { title }
}

struct OnboardingPersonalizationView: View {
  let isYes: Bool
  let onContinue: () -> Void

  @ObservedObject private var healthManager = HealthManager.shared

  @State private var index = 0

  @FocusState private var isFocused: Bool

  private let suggestions = [
    FocusPair(
      symbol: .heartFill,
      title: "Understand my health data",
      color: .mutedPink
    ),
    FocusPair(
      symbol: .battery100percentBolt,
      title: "Boost energy levels",
      color: .mutedOrange
    ),
    FocusPair(
      symbol: .moonZzzFill,
      title: "Improve sleep",
      color: .mutedIndigo
    ),
    FocusPair(
      symbol: .figureRun,
      title: "Build healthier habits",
      color: .mutedGreen
    ),
    FocusPair(
      symbol: .boltFill,
      title: "Reduce stress",
      color: .mutedYellow
    ),
    FocusPair(
      symbol: .gaugeWithDotsNeedle33percent,
      title: "Improve my body composition",
      color: .mutedBlue
    )
  ]

  var body: some View {
    BloomScrollView(showsChatBar: false, padding: .bottom) {
      ZStack {
        Image(.afternoonScenery)
          .resizable()
          .scaledToFit()
          .parallaxOverscroll()
          .zStackAlignment(.top)

        VStack(alignment: .leading) {
          BudImage(.budCoach, dimension: 200)
            .horizontallyCentered()

          discussionSection
        }
        .horizontalAlignment(.leading)
        .padding(.top, 160)
      }
    }
    .animation(.default, value: index)
    .sensoryFeedback(.impact, trigger: index)
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
  }

  @ViewBuilder
  var discussionSection: some View {
    if index >= 1 {
      Text(isYes ? "Awesome!" : "Totally!")
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
        Text(isYes ? "Let's make Bloom work perfectly for you." : "Here's how I help people stay focused on what matters most for their health.")
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
    
    if index >= 4 {
      focusAreaSection
        .transition(.move(edge: .bottom))

      textInputSection
        .transition(.blurReplace)
    }
  }

  var focusAreaSection: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 400), spacing: 12)], spacing: 12) {
      ForEach(suggestions) { suggestion in
        FocusCardCell(
          title: suggestion.title,
          symbol: suggestion.symbol,
          isSelected: false
        )
        .transition(.scale)
        .tint(suggestion.color)
      }
    }
    .padding(.horizontal)
    .padding(.top)
  }

  var textInputSection: some View {
    HStack {
      Image(systemSymbol: .sparkles)
        .font(.title2)
        .foregroundStyle(.mutedLightBlue)

      TextField(
        "",
        text: $healthManager.focus,
        prompt: Text("Something else..."),
        axis: .vertical
      )
    }
    .multilineTextAlignment(.leading)
    .secondaryOnboardingTextStyle()
    .cardContainer()
    .focused($isFocused)
    .contentTransition(.numericText())
    .padding(.horizontal)
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
    OnboardingPersonalizationView(isYes: true) { }
  }
}

#Preview("No") {
  PreviewEnvironment {
    OnboardingPersonalizationView(isYes: false) { }
  }
}

