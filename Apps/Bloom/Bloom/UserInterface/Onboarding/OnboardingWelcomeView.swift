//
//  OnboardingWelcomeView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI
import AppUI
import TelemetryDeck

struct OnboardingWelcomeView: View {
  var onContinue: () -> Void

  @State private var index = 1
  @State private var didContinue = false
  @State private var isNameUnknown: Bool?
  @FocusState private var isFocused: Bool

  @ObservedObject private var healthManager = HealthManager.shared

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        if let isNameUnknown {
          if isNameUnknown {
            unknownNameContent
          } else {
            knownNameContent
          }
        } else {
          EmptyView()
        }
      }
      .padding()
      .horizontalAlignment(.leading)
    }
    .onboardingTextStyle()
    .topSafeAreaFill(.background)
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.selection, trigger: didContinue)
    .animation(.default, value: index)
    .if(index >= 4) {
      $0.shelf {
        Button("Sounds great!") {
          didContinue.toggle()
          onContinue()
        }
        .buttonStyle(.onboarding)
        .disabled(healthManager.name.isEmpty)
      }
    }
    .task {
      while index < 3 {
        await advanceIndex()
      }

      if isNameUnknown == false {
        await advanceIndex()
      }
    }
    .onAppear {
      if isNameUnknown == nil {
        isNameUnknown = healthManager.name.isEmpty
      }
      TelemetryDeck.signal("OB Welcome")
    }
  }
}

private extension OnboardingWelcomeView {

  @ViewBuilder
  var knownNameContent: some View {
    DisplayAppIcon()
      .frame(width: 100)

    Text("Hey \(healthManager.name)!")
      .appear(with: 1, currentIndex: index)

    Text("I'm Bloom, your new personal Health Assistant.")
      .transition(.opacity)
      .appear(with: 2, currentIndex: index)

    Text("It's nice to meet you! Let's get to know each other a bit...")
      .transition(.opacity)
      .appear(with: 3, currentIndex: index)
  }

  @ViewBuilder
  var unknownNameContent: some View {
    DisplayAppIcon()
      .frame(width: 100)

    Text("Hey there!")
      .appear(with: 1, currentIndex: index)

    Text("I'm Bloom, your new personal Health Assistant.")
      .transition(.opacity)
      .appear(with: 2, currentIndex: index)

    Group {
      Text("What's your first name?")

      TextField("", text: $healthManager.name, prompt: Text("Your Name"))
        .textContentType(.givenName)
        .cardContainer(fill: .background.secondary)
        .focused($isFocused)
        .submitLabel(.done)
        .onSubmit {
          didSubmitName()
        }
        .onAppear {
          isFocused = true
        }
        .onChange(of: healthManager.name) { oldValue, newValue in
          if
            newValue.isNotEmpty &&
            newValue.count >= 2 &&
            oldValue.isEmpty
          {
            didSubmitName()
          }
        }
    }
    .transition(.blurReplace)
    .appear(with: 3, currentIndex: index, secondaryIfNotCurrentIndex: false)

    Text("Nice to meet you, \(healthManager.name)! Let's get to know each other a bit...")
      .transition(.opacity)
      .appear(with: 4, currentIndex: index)

    Spacer()
  }
}

private extension OnboardingWelcomeView {

  func didSubmitName() {
    guard healthManager.name.isNotEmpty else { return }

    isFocused = false
    withAnimation {
      index += 1
    }
  }

  func advanceIndex() async {
    await Delay(1700)

    index += 1
  }
}

#Preview {
  OnboardingWelcomeView { }
}
