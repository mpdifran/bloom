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
import CoreHealth
import SFSafeSymbols

struct OnboardingAppExplanationView: View {
  var onContinue: () async -> Void

  @State private var vitalPairs = [VitalOffsetPair]()

  @State private var animationCount = 0
  @State private var index = 0
  @State private var didContinue = false
  @State private var showTennis = false
  @State private var showWaterBottle = false
  @State private var showBasketball = false

  @ObservedObject private var healthManager = HealthManager.shared

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        if index >= 1 {
          BudImage(.budSmoothie, dimension: 200)

          Text("Nice to meet you \(healthManager.name), I'm Bud!")
            .fixedSize(horizontal: false, vertical: true)
            .transition(.blurReplace)
        }

        if index >= 2 {
          Text("Ask me anything about your health, and I’ll give you smart, personalized advice based on your data — no guesswork, no stress.")
            .font(.title3)
            .fixedSize(horizontal: false, vertical: true)
            .transition(.blurReplace)
            .foregroundStyle(.secondary)
        }

        if index >= 3 {
          Text("Need help with nutrition? Want a custom workout plan? Ready to set (and actually hit) your goals? I’ve got you covered.")
            .font(.title3)
            .fixedSize(horizontal: false, vertical: true)
            .transition(.blurReplace)
            .foregroundStyle(.secondary)
        }

        if index >= 4 {
          HStack {
            Spacer()
            Image(systemSymbol: .tennisRacket)
              .opacity(showTennis ? 1 : 0)
              .scaleEffect(showTennis ? 1 : 0.5)
              .animation(.bouncy, value: showTennis)
            Spacer()
            Image(systemSymbol: .waterbottle)
              .opacity(showWaterBottle ? 1 : 0)
              .scaleEffect(showWaterBottle ? 1 : 0.5)
              .animation(.bouncy, value: showWaterBottle)
            Spacer()
            Image(systemSymbol: .basketball)
              .opacity(showBasketball ? 1 : 0)
              .scaleEffect(showBasketball ? 1 : 0.5)
              .animation(.bouncy, value: showBasketball)
            Spacer()
          }
          .font(.system(size: 40))
          .foregroundStyle(.tint)
        }
      }
      .horizontalAlignment(.leading)
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
      AsyncButton {
        didContinue.toggle()
        await onContinue()
      } label: {
        Text("Hi Bud!")
      }
      .buttonStyle(.onboarding)
    }
    .task {
      await startAnimation()
    }
    .task {
      while index < 4 {
        await advanceIndex()
      }
      // Animate symbols after index 4
      await Delay(200)
      showTennis = true
      await Delay(200)
      showWaterBottle = true
      await Delay(200)
      showBasketball = true
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
            id: .heartHealth,
            subtitle: nil,
            status: "Healthy",
            color: .vitalGood,
            barLevel: VitalModel.BarLevel(level: .high, proportion: 0.8),
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
