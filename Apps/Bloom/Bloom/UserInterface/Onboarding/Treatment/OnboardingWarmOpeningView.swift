//
//  OnboardingWarmOpeningView.swift
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

struct OnboardingWarmOpeningView: View {
  var onContinue: (Bool) -> Void

  @State private var showBud = false
  @State private var confettiIndex = 0
  @State private var index = 0
  @State private var continueToggle = false

  var body: some View {
    BloomScrollView(padding: .bottom) {
      ZStack {
        Image(.morningScenery)
          .resizable()
          .scaledToFit()
          .offset(y: -40)
          .parallaxOverscroll()
          .zStackAlignment(.top)

        VStack {
          if showBud {
            BudImage(.budRunning, dimension: 260)
              .transition(.move(edge: .leading))
              .standardConfetti(
                $confettiIndex,
                colors: [.mutedBlue, .mutedOrange, .white]
              )
          }
          helloSection
        }
        .padding(.top, 100)
      }
    }
    .removeScrollEdgeEffect(shouldHide: true)
    .ignoresSafeArea(.all, edges: .top)
    .animation(.default, value: showBud)
    .animation(.bouncy, value: index)
    .sensoryFeedback(.success, trigger: showBud)
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.impact, trigger: continueToggle)
    .shelf(isVisible: index >= 4) {
      HStack {
        Button {
          TelemetryDeck.signal("OB Warm Opening - Tell me more")
          continueToggle.toggle()
          onContinue(false)
        } label: {
          Text("Tell me more")
            .horizontallyCentered()
        }
        .buttonStyle(.primaryAlternate)

        Button {
          TelemetryDeck.signal("OB Warm Opening - Yes Bud")
          continueToggle.toggle()
          onContinue(true)
        } label: {
          Text("Yes, Bud!")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
      }
    }
    .task {
      await advanceIndex()
    }
    .onAppear {
      TelemetryDeck.signal("OB Warm Opening")
      TelemetryDeck.startDurationSignal("Onboarding V2")
    }
  }
}

private extension OnboardingWarmOpeningView {

  func advanceIndex() async {
    await Delay(300)
    withAnimation {
      showBud = true
    }
    await Delay(300)
    confettiIndex += 1
    index += 1
    await Delay(800)
    index += 1
    await Delay(800)
    index += 1
    await Delay(1000)
    withAnimation {
      index += 1
    }
  }

  @ViewBuilder
  var helloSection: some View {
    VStack(alignment: .leading) {
      if index >= 1 {
        Text("Hey there! I'm Bud 👋")
          .primaryOnboardingTextStyle()
          .padding(.horizontal)
          .transition(.blurReplace)
      }

      if index >= 2 {
        ChatBubble(
          position: .leading,
          showTail: true,
          backgroundStyle: .background
        ) {
          Text("Health data can feel overwhelming. I’m here to make things simple.")
            .secondaryOnboardingTextStyle()
        }
        .transition(.move(edge: .leading))
      }

      if index >= 3 {
        ChatBubble(
          position: .leading,
          showTail: true,
          backgroundStyle: .background
        ) {
          Text("Want me to help you stay focused on what matters most for your health?")
            .secondaryOnboardingTextStyle()
        }
        .transition(.move(edge: .leading))
      }
    }
    .horizontalAlignment(.leading)
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingWarmOpeningView() { (_) in }
  }
}
