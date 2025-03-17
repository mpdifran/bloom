//
//  OnboardingAppExplanationView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-24.
//

import SwiftUI
import DataContainer
import AppUI
import TelemetryDeck

struct OnboardingAppExplanationView: View {
  var onContinue: () -> Void

  @State private var vitalPairs = [VitalOffsetPair]()

  @State private var animationCount = 0
  @State private var index = 0
  @State private var didContinue = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        vitalsCardPileView

        Spacer(minLength: 40)

        if index >= 1 {
          Text("The Power of Vitals")
            .fixedSize(horizontal: false, vertical: true)
            .transition(.blurReplace)
        }

        if index >= 2 {
          Text("Bloom categorizes your health data into vitals, helping you focus on what's really important.")
            .font(.title3)
            .fixedSize(horizontal: false, vertical: true)
            .transition(.blurReplace)
            .foregroundStyle(.secondary)
        }

        if index >= 3 {
          Text("You'll then get personalized goals to help improve each part of your health!")
            .font(.title3)
            .fixedSize(horizontal: false, vertical: true)
            .transition(.blurReplace)
            .foregroundStyle(.secondary)
        }
      }
      .padding()
      .onboardingTextStyle()
    }
    .groupedBackground()
    .animation(.default, value: vitalPairs.count)
    .animation(.default, value: index)
    .sensoryFeedback(.selection, trigger: vitalPairs.count)
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.selection, trigger: didContinue)
    .shelf {
      Button("Neat!") {
        didContinue.toggle()
        onContinue()
      }
      .buttonStyle(.onboarding)
    }
    .task {
      await startAnimation()
    }
    .task {
      //            await Delay(2000)

      while index < 3 {
        await advanceIndex()
      }
    }
    .onAppear {
      TelemetryDeck.signal("OB App Explanation")
    }
  }
}

private extension OnboardingAppExplanationView {

  var vitalsCardPileView: some View {
    VStack {
      HStack {
        Spacer()
      }
      ForEachEnumerated(vitalPairs) { (index, vitalPair) in
        MiniVitalCell(
          vital: vitalPair.vital
        )
        .transition(.blurReplace)
      }
    }
    .frame(height: 270)
  }
}

private extension OnboardingAppExplanationView {

  func advanceIndex() async {
    await Delay(200)

    index += 1
  }

  func startAnimation() async {
    var hasFinished = false
    while !hasFinished {
      hasFinished = await advanceVitals()
    }

    animationCount += 1

    await Delay(3000)

    guard animationCount < 4 else { return }

    vitalPairs.removeAll(keepingCapacity: true)

    await doTheThing()
  }

  func doTheThing() async {
    await startAnimation()
  }

  func advanceVitals() async -> Bool {
    await Delay(1000)

    switch vitalPairs.count {
    case 0:
      vitalPairs.append(
        VitalOffsetPair(
          vital: VitalModel(
            id: .activityLevel,
            subtitle: nil,
            status: "Moderate",
            color: .vitalGood,
            barLevel: VitalModel.BarLevel(level: .high, proportion: 0.3),
            hasNoData: false
          ),
          rotation: .degrees(6),
          offset: -40
        )
      )
    case 1:
      vitalPairs.append(
        VitalOffsetPair(
          vital: VitalModel(
            id: .sleepQuality,
            subtitle: nil,
            status: "Low",
            color: .vitalWarning,
            barLevel: VitalModel.BarLevel(level: .medium, proportion: 0.2),
            hasNoData: false
          ),
          rotation: .degrees(-5),
          offset: 10
        )
      )
    case 2:
      vitalPairs.append(
        VitalOffsetPair(
          vital: VitalModel(
            id: .cycleTracking,
            subtitle: nil,
            status: "Luteal Phase",
            color: .mutedIndigo,
            barLevel: nil,
            hasNoData: false
          ),
          rotation: .degrees(2),
          offset: 60
        )
      )
    case 3:
      vitalPairs.append(
        VitalOffsetPair(
          vital: VitalModel(
            id: .nutrition,
            subtitle: nil,
            status: "Great",
            color: .vitalGreat,
            barLevel: VitalModel.BarLevel(level: .optimal, proportion: 0.4),
            hasNoData: false
          ),
          rotation: .degrees(-2),
          offset: 100
        )
      )
    default:
      return true
    }

    return false
  }
}

struct VitalOffsetPair: Identifiable {
  var id: VitalModel.Kind { vital.id }

  let vital: VitalModel
  let rotation: Angle
  let offset: CGFloat
}

#Preview {
  PreviewEnvironment {
    OnboardingAppExplanationView { }
  }
}
