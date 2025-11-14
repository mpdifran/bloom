//
//  OnboardingExplanationTodayInsightsView.swift
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

struct OnboardingExplanationTodayInsightsView: View {
  let onContinue: () -> Void

  @State private var index = 0

  var body: some View {
    BloomScrollView(padding: .bottom) {
      ZStack {
        Image(.morningScenery)
          .resizable()
          .scaledToFit()
          .parallaxOverscroll()
          .zStackAlignment(.top)

        VStack {
          BudImage(.budRunning, dimension: 180)
          helloSection
          todayInsightSection
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
        Text("That's Cool!")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    }
    .onAppear {
      TelemetryDeck.signal("OB Today Insights Explanation")
    }
  }
}

private extension OnboardingExplanationTodayInsightsView {

  var helloSection: some View {
    Text("Hi there, I'm Bud!")
      .font(.title)
      .bold()
      .fontDesign(.rounded)
      .horizontalAlignment(.leading)
      .padding(.horizontal)
  }

  var todayInsightSection: some View {
    VStack(alignment: .leading) {
      Text("I can give you insights into your health every day!")
        .font(.title3)
        .bold()
        .fontDesign(.rounded)
        .transition(.blurReplace)
        .foregroundStyle(.secondary)
        .padding(.horizontal)

      if index >= 1 {
        TodaysAdviceTodayCell(advice: "Let's focus on your workout goal today. Just 20 minutes of exercise should keep us on track for the rest of the week.")
          .transition(.blurReplace)
          .padding(.horizontal)
      }
      if index >= 2 {
        InsightTodayCell(
          insights: [
            TodayReportResponse.HealthInsight(
              title: "Watch your sodium intake",
              body: "You had 2,800 mg of sodium yesterday — a little high. Maybe skip the chips today?",
              priority: 8
            ),
            TodayReportResponse.HealthInsight(
              title: "Great job on your bike ride yesterday",
              body: "You biked 12.6 km in 42 minutes — your longest weekday ride yet!",
              priority: 2
            )
          ],
          allowContextMenu: false
        )
        .transition(.blurReplace)
      }
    }
    .horizontalAlignment(.leading)
    .fixedSize(horizontal: false, vertical: true)
    .task {
      await advanceIndex()
    }
  }
}

private extension OnboardingExplanationTodayInsightsView {

  func advanceIndex() async {
    await Delay(1200)
    index += 1
    await Delay(200)
    index += 1
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingExplanationTodayInsightsView() { }
  }
}
