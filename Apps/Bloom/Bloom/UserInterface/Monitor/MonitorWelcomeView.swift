//
//  MonitorWelcomeView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-16.
//

import SwiftUI
import SFSafeSymbols
import DataContainer
import BloomUI
import BloomFoundation

struct MonitorWelcomeView: View {

  @Binding var presentedSheet: AnyView?

  @State private var minZScore: Double = -0.8
  @State private var maxZScore: Double = 1.6
  @State private var metricZScores: [MetricZScorePoint] = []
  @State private var stateIndex = 0

  private let barStates: [(min: Double, max: Double, metrics: [MetricZScorePoint])] = [
    (-0.8, 1.6, [MetricZScorePoint(metricType: "demo", zScore: 1)]),
    (-0.8, 2.8, [MetricZScorePoint(metricType: "demo", zScore: 2.2)]),
    (-2.8, 0.2, [MetricZScorePoint(metricType: "demo", zScore: -1.5)]),
    (-2.0, 2.0, [MetricZScorePoint(metricType: "demo", zScore: 0.5)]),
  ]

  var body: some View {
    BloomScrollView {
      titleCard
    }
  }
}

private extension MonitorWelcomeView {

  var titleCard: some View {
    VStack {
      Circle()
        .fill(
          LinearGradient(
            colors: [
              .monitorLow,
              .monitorTypical,
              .monitorHigh
            ],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .frame(square: 60)
        .overlay {
          Image(systemSymbol: .waveformPathEcg)
            .font(.largeTitle)
            .fontWeight(.heavy)
            .foregroundStyle(.white)
        }
        .padding(.top)

      Text("Monitor")
        .font(.largeTitle)
        .bold()
        .padding(.bottom)

      Text("Bloom learns your baseline for stress, recovery, and sleep, then alerts you when something's off. It can even detect early signs of illness before you feel it.")
        .font(.body)
        .foregroundStyle(.secondary)
        .horizontalAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom)

      MonitorSummaryBar(
        data: MonitorSummaryBarData(
          metricZScores: metricZScores,
          minZScore: minZScore,
          maxZScore: maxZScore
        )
      )

      Button {
        presentedSheet = BloomPlusPaywall(focus: .monitor, onDismiss: {
          guard EntitlementController.shared.hasBloomPro == true else { return }

          Task {
            await Delay(300)
            presentedSheet = WelcomeToBloomPlusView {
              // MonitorView will reactively show content
            }.asAny
          }
        }).asAny
      } label: {
        Text("Turn On Monitor")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
      .padding(.top)
    }
    .horizontallyCentered()
    .cardContainer()
    .animation(.default, value: metricZScores)
    .animation(.default, value: minZScore)
    .animation(.default, value: maxZScore)
    .task {
      await runBarLoop()
    }
  }

  func runBarLoop() async {
    while true {
      await Delay(3000)
      stateIndex = (stateIndex + 1) % barStates.count
      let state = barStates[stateIndex]
      minZScore = state.min
      maxZScore = state.max
      metricZScores = state.metrics
    }
  }
}

#Preview {
  PreviewEnvironment {
    MonitorWelcomeView(presentedSheet: .constant(nil))
  }
}
