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

  var body: some View {
    BloomScrollView(showsChatBar: false, padding: .bottom) {
      ZStack {
        Image(.morningScenery)
          .resizable()
          .scaledToFit()
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
        .padding(.top, 160)
      }
    }
    .removeScrollEdgeEffect(shouldHide: true)
    .ignoresSafeArea(.all, edges: .top)
    .animation(.default, value: showBud)
    .animation(.bouncy, value: index)
    .sensoryFeedback(.success, trigger: showBud)
    .sensoryFeedback(.impact, trigger: index)
    .shelf(isVisible: index >= 4) {
      HStack {
        Button {
          onContinue(false)
        } label: {
          Text("Tell me more")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .tint(.gray)

        Button {
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
