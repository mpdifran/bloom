//
//  MonitorWelcomeView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-16.
//

import SwiftUI
import SFSafeSymbols
import DataContainer

struct MonitorWelcomeView: View {

  @State private var fakeIsMonitorEnabled = false

  var body: some View {
    BloomScrollView {
      titleCard
      toggleSection
    }
  }
}

private extension MonitorWelcomeView {

  var titleCard: some View {
    VStack {
      Image(systemSymbol: .waveformPathEcg)
        .font(.largeTitle)
        .fontWeight(.heavy)
        .foregroundStyle(
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
        .padding(.top)

      Text("Monitor")
        .font(.largeTitle)
        .bold()
        .padding(.bottom)

      Text("Bloom learns your baseline for stress, recovery, and sleep, then alerts you when something's off. It can even detect early signs of illness before you feel it.")
        .font(.body)
        .foregroundStyle(.secondary)
        .horizontalAlignment(.leading)
        .padding(.bottom)

      MonitorSummaryBar(
        data: MonitorSummaryBarData(
          metricZScores: [],
          min7DayZScore: -0.8,
          max7DayZScore: 1.6
        )
      )
    }
    .horizontallyCentered()
    .cardContainer()
  }

  var toggleSection: some View {
    Toggle(isOn: $fakeIsMonitorEnabled) {
      Text("Enable Monitor")
        .bold()
    }
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    MonitorWelcomeView()
  }
}
