//
//  BloomPlusMonitorCardShowcaseCell.swift
//  Bloom
//

import SwiftUI
import BloomUI
import DataContainer

struct BloomPlusMonitorCardShowcaseCell: View {

  @State private var height: CGFloat = 1
  @State private var selectedIndex = 0

  private let timer = Timer.publish(every: 7, on: .main, in: .common).autoconnect()
  private let totalCards = 3

  var body: some View {
    TabView(selection: $selectedIndex) {
      // Card 1: Recovery & Sickness
      BloomPlusTodayCardShowcaseCard(
        title: "Catch Illness Before It Catches You",
        message: "Bloom tracks subtle shifts in your heart rate, HRV, and temperature. When patterns suggest you might be getting sick, you'll know before symptoms hit."
      ) {
        recoveryMonitorVisualization
      }
      .tag(0)
      .padding(.horizontal)
      .readViewSize { proxy in
        if proxy.size.height > height {
          self.height = proxy.size.height
        }
      }

      // Card 2: Stress & Workout Load
      BloomPlusTodayCardShowcaseCard(
        title: "Train Smarter, Not Harder",
        message: "Detect signs of burnout and overtraining before they catch up to you. Balance physical stress, mental recovery, and workout load for better results."
      ) {
        stressMonitorVisualization
      }
      .tag(1)
      .padding(.horizontal)
      .readViewSize { proxy in
        if proxy.size.height > height {
          self.height = proxy.size.height
        }
      }

      // Card 3: Sleep Quality & Rhythm
      BloomPlusTodayCardShowcaseCard(
        title: "Protect Your Sleep Foundation",
        message: "Track sleep duration, deep sleep, and consistency. Get alerted when your rhythm is off so you can course-correct before fatigue builds up."
      ) {
        sleepMonitorVisualization
      }
      .tag(2)
      .padding(.horizontal)
      .readViewSize { proxy in
        if proxy.size.height > height {
          self.height = proxy.size.height
        }
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .automatic))
    .frame(height: height)
    .onReceive(timer) { _ in
      withAnimation {
        selectedIndex = (selectedIndex + 1) % totalCards
      }
    }
  }
}

// MARK: - Monitor Visualizations

private extension BloomPlusMonitorCardShowcaseCell {

  var recoveryMonitorVisualization: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Recovery & Sickness")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
        MonitorStateBadge(state: .attention)
      }

      Text("Elevated for 2 days")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      MonitorSummaryBar(
        data: MonitorSummaryBarData(
          metricZScores: [
            MetricZScorePoint(metricType: "rhr", zScore: 1.4),
            MetricZScorePoint(metricType: "hrv", zScore: 1.2),
            MetricZScorePoint(metricType: "temp", zScore: 1.6)
          ],
          minZScore: 0.3,
          maxZScore: 1.8
        )
      )
    }
    .padding()
    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 24))
  }

  var stressMonitorVisualization: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Stress & Workout Load")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
        MonitorStateBadge(state: .alert)
      }

      Text("Training load +25%")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      MonitorSummaryBar(
        data: MonitorSummaryBarData(
          metricZScores: [
            MetricZScorePoint(metricType: "trainingLoad", zScore: 1.8),
            MetricZScorePoint(metricType: "hrRecovery", zScore: 0.5)
          ],
          minZScore: 0.2,
          maxZScore: 2.0
        )
      )
    }
    .padding()
    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 24))
  }

  var sleepMonitorVisualization: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Sleep Quality & Rhythm")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
        MonitorStateBadge(state: .good)
      }

      Text("Consistent this week")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      MonitorSummaryBar(
        data: MonitorSummaryBarData(
          metricZScores: [
            MetricZScorePoint(metricType: "duration", zScore: 0.2),
            MetricZScorePoint(metricType: "deepSleep", zScore: -0.3),
            MetricZScorePoint(metricType: "efficiency", zScore: 0.1)
          ],
          minZScore: -0.6,
          maxZScore: 0.5
        )
      )
    }
    .padding()
    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 24))
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView(padding: []) {
      BloomPlusMonitorCardShowcaseCell()
    }
  }
}
