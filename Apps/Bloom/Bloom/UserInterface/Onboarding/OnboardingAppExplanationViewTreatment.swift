//
//  OnboardingAppExplanationViewTreatment.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-24.
//

import SwiftUI
import DataContainer
import AppUI
import TelemetryDeck
import CoreHealth
import SFSafeSymbols

struct OnboardingAppExplanationViewTreatment: View {
  var onContinue: () async -> Void

  @State private var animationCount = 0
  @State private var index = 0
  @State private var showContinue = false
  @State private var didContinue = false

  @ObservedObject private var healthManager = HealthManager.shared

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        VStack(alignment: .leading, spacing: 10) {
          if index >= 1 {
            BudImage(.budSmoothie, dimension: 200)

            Text("Nice to meet you \(healthManager.name), I'm Bud!")
              .fixedSize(horizontal: false, vertical: true)
              .transition(.blurReplace)
          }

          if index >= 2 {
            Text("You can ask me anything, and I'll answer using your health data.")
              .font(.title3)
              .fixedSize(horizontal: false, vertical: true)
              .transition(.blurReplace)
              .foregroundStyle(.secondary)
          }
        }
        .padding()
        .horizontalAlignment(.leading)

        Group {
          if index >= 3 {
            ChatBubbleCell(
              message: "How has my sleep been this week?",
              isDirect: false,
              isCurrentUser: true,
              showTail: true
            )
            .transition(.blurReplace)
          }

          if index == 4 {
            TypingIndicatorCell(isDirect: false)
              .transition(.blurReplace)
          } else if index == 5 {
            Text("Reading sleep data...")
              .font(.headline)
              .bold()
              .foregroundStyle(.secondary)
              .fontDesign(.rounded)
              .multilineTextAlignment(.leading)
              .contentTransition(.numericText())
              .padding()
              .transition(.blurReplace)
          } else if index >= 6 {
            ChatBubbleCell(
              message: "You’ve been getting about 7 hours of sleep per night this week. A bit less deep sleep than usual, so you might feel a touch more tired in the afternoons. Try winding down 30 minutes earlier tonight to help!",
              isDirect: false,
              isCurrentUser: false,
              showTail: true
            )
            .horizontalAlignment(.leading)
            .transition(.blurReplace)
          }
        }
        .font(.title3)

        if index >= 7 {
          Button {
            index = 2
            Task {
              while index < 7 {
                await advanceIndex()
              }
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
      .onboardingTextStyle()
    }
    .groupedBackground()
    .animation(.default, value: index)
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.selection, trigger: didContinue)
    .shelf {
      if showContinue {
        AsyncButton {
          didContinue.toggle()
          await onContinue()
        } label: {
          Text("Neat!")
        }
        .buttonStyle(.onboarding)
      }
    }
    .task {
      while index < 7 {
        await advanceIndex()
      }
    }
    .onAppear {
      TelemetryDeck.signal("OB App Explanation")
      TelemetryDeck.signal("AB: OB App Explanation Treatment")
    }
  }
}

private extension OnboardingAppExplanationViewTreatment {

  func advanceIndex() async {
    if index < 2 {
      await Delay(200)
    } else {
      await Delay(1000)
    }

    index += 1

    if index >= 7 {
      showContinue = true
    }
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingAppExplanationViewTreatment { }
  }
}
