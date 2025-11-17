//
//  OnboardingExplanationChatView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-11.
//

import SwiftUI
import AppUI
import BloomUI
import BloomModel
import BloomFoundation
import TelemetryDeck

struct OnboardingExplanationChatView: View {
  let onContinue: () -> Void

  @State private var index = 0

  var body: some View {
    BloomScrollView(padding: .bottom) {
      ZStack {
        Image(.afternoonScenery)
          .resizable()
          .scaledToFit()
          .parallaxOverscroll()
          .zStackAlignment(.top)


        VStack {
          BudImage(.budBicycle, dimension: 200)
          helloSection
          chatSection
        }
        .padding(.top, 160)
      }
    }
    .removeScrollEdgeEffect(shouldHide: true)
    .ignoresSafeArea(.all, edges: .top)
    .animation(.bouncy, value: index)
    .sensoryFeedback(.impact, trigger: index)
    .shelf {
      Button {
        index += 1
        onContinue()
      } label: {
        Text("Neat-O!")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    }
    .onAppear {
      TelemetryDeck.signal("OB Chat Explanation")
    }
  }
}

private extension OnboardingExplanationChatView {

  var helloSection: some View {
    Text("You can ask me anything!")
      .font(.title)
      .bold()
      .fontDesign(.rounded)
      .horizontalAlignment(.leading)
      .padding(.horizontal)
  }

  var chatSection: some View {
    VStack(alignment: .leading) {
      Text("I'll answer by referencing your personal data.")
        .font(.title3)
        .bold()
        .fontDesign(.rounded)
        .transition(.blurReplace)
        .foregroundStyle(.secondary)
        .padding(.horizontal)

      if index >= 1 {
        ChatBubbleCell(
          message: "How has my sleep been this week?",
          isDirect: false,
          isCurrentUser: true,
          showTail: true
        )
        .transition(.blurReplace)
      }

      if index == 2 {
        TypingIndicatorCell(isDirect: false)
          .transition(.blurReplace)
      } else if index == 3 {
        Text("Reading sleep data...")
          .font(.headline)
          .bold()
          .foregroundStyle(.secondary)
          .fontDesign(.rounded)
          .multilineTextAlignment(.leading)
          .contentTransition(.numericText())
          .shimmer()
          .padding()
          .transition(.blurReplace)
      } else if index >= 4 {
        ChatBubbleCell(
          message: "You’ve been getting about 7 hours of sleep per night this week. A bit less deep sleep than usual, so you might feel a touch more tired in the afternoon. Try winding down 30 minutes earlier tonight to help!",
          isDirect: false,
          isCurrentUser: false,
          showTail: true
        )
        .horizontalAlignment(.leading)
        .transition(.blurReplace)
      }

      if index >= 5 {
        Button {
          index = 0
          Task {
            await advanceIndex()
          }
        } label: {
          HStack {
            Image(systemSymbol: .arrowCounterclockwise)
            Text("Replay")
          }
          .bold()
        }
        .frame(height: 50)
        .font(.headline)
        .horizontallyCentered()
      }
    }
    .horizontalAlignment(.leading)
    .fixedSize(horizontal: false, vertical: true)
    .task {
      await advanceIndex()
    }
  }
}

private extension OnboardingExplanationChatView {

  func advanceIndex() async {
    await Delay(500)
    index += 1
    await Delay(800)
    index += 1
    await Delay(1000)
    index += 1
    await Delay(1600)
    index += 1
    await Delay(1400)
    index += 1
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingExplanationChatView() { }
  }
}
