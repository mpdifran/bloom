//
//  OnboardingExplanationBioAgeView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-11.
//

import SwiftUI
import AppUI
import BloomUI
import BloomModel
import BloomFoundation
import DataContainer
import TelemetryDeck

struct OnboardingExplanationBioAgeView: View {
  let onContinue: () -> Void

  @State private var index = 0
  @State private var mockBioAge = 30
  @State private var ageOffset = 0
  @State private var ageTickerActive = true

  var body: some View {
    BloomScrollView(padding: .bottom) {
      ZStack {
        Image(.eveningScenery)
          .resizable()
          .scaledToFit()
          .parallaxOverscroll()
          .zStackAlignment(.top)

        VStack {
          BudImage(.budCoach, dimension: 200)
          helloSection
          biologicalAgeSection
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
        Text("Thanks Bud!")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    }
    .onAppear {
      TelemetryDeck.signal("OB Bio Age Explanation")
    }
  }
}

private extension OnboardingExplanationBioAgeView {

  var helloSection: some View {
    Text("I've got your back!")
      .font(.title)
      .bold()
      .fontDesign(.rounded)
      .horizontalAlignment(.leading)
      .padding(.horizontal)
  }

  var biologicalAgeSection: some View {
    VStack(alignment: .leading) {
      Text("I can calculate your biological age and keep track of your vitals.")
        .font(.title3)
        .bold()
        .fontDesign(.rounded)
        .transition(.blurReplace)
        .foregroundStyle(.secondary)

      if index >= 1 {
        BiologicalAgeMeter(
          chronologicalAge: 30.0,
          biologicalAge: Double(30 + ageOffset)
        )
        .frame(square: 130)
        .horizontallyCentered()
        .cardContainer()
        .transition(.blurReplace)
        .onAppear {
          // Initial quick demo animation can remain if desired
          withAnimation { mockBioAge = 26 }

          // Start a repeating ticker to vary ageOffset between -10 and 10 every 3 seconds
          ageTickerActive = true
          Task { @MainActor in
            while ageTickerActive {
              let newOffset = Int.random(in: -10...10)
              withAnimation(.easeInOut(duration: 0.6)) {
                ageOffset = newOffset
              }
              await Delay(3000)
            }
          }
        }
        .onDisappear {
          // Stop the ticker when this section goes away
          ageTickerActive = false
        }
      }

      if index >= 2 {
        MonthlyVitalCardCell(
          vital: VitalModel(
            id: .heartHealth,
            subtitle: "RHR: 65 bpm",
            status: index <= 2 ? "OK" : "Optimal",
            color: index <= 2 ? .mutedYellow : .mutedBlue,
            barLevel: index <= 2 ? VitalModel.BarLevel(level: .medium, proportion: 0.7) : VitalModel.BarLevel(level: .optimal, proportion: 0.4),
            hasNoData: false
          )
        )
        .transition(.blurReplace)
      }

      if index >= 3 {
        MonthlyVitalCardCell(
          vital: VitalModel(
            id: .sleepQuality,
            subtitle: "Avg 7hr, 32min",
            status: index <= 3 ? "Poor" : "Good",
            color: index <= 3 ? .mutedYellow : .mutedGreen,
            barLevel: index <= 3 ? VitalModel.BarLevel(level: .medium, proportion: 0.2) : VitalModel.BarLevel(level: .high, proportion: 0.8),
            hasNoData: false
          )
        )
        .transition(.blurReplace)
      }
    }
    .padding(.horizontal)
    .horizontalAlignment(.leading)
    .fixedSize(horizontal: false, vertical: true)
    .task {
      await advanceIndex()
    }
  }
}

private extension OnboardingExplanationBioAgeView {

  func advanceIndex() async {
    await Delay(500)
    index += 1
    await Delay(300)
    index += 1
    await Delay(300)
    index += 1
    await Delay(300)
    index += 1
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingExplanationBioAgeView() { }
  }
}
