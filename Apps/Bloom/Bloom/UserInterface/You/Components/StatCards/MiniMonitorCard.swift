//
//  MiniMonitorCard.swift
//  Bloom
//
//  Created by Claude on 2026-07-23.
//

import SwiftUI
import SFSafeSymbols
import DataContainer
import CoreHealth

/// A compact card summarizing a single health monitor's state, shown on the You tab.
struct MiniMonitorCard: View {

  let type: MonitorType
  let state: MonitorStateValue

  @State private var summaryBarData: MonitorSummaryBarData?

  private var displayBarData: MonitorSummaryBarData {
    summaryBarData ?? .empty
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text(title)
        .font(.caption)
        .bold()

      Spacer()

      MonitorSummaryBar(data: displayBarData, hasData: summaryBarData != nil, showsLabels: false, barHeight: 14, dotSize: 8)
    }
    .frame(maxWidth: .infinity)
    .task {
      await loadSummaryBarData()
    }
  }
}

private extension MiniMonitorCard {

  var title: String {
    switch type {
    case .recovery: String(localized: "Recovery & Sickness")
    case .stress: String(localized: "Stress & Workout Load")
    case .sleep: String(localized: "Sleep Quality & Rhythm")
    }
  }

  // MARK: - Summary bar data (mirrors MonitorCard.loadSummaryBarData)

  func loadSummaryBarData() async {
    do {
      let actor = DailyMetricSampleModelActor.standard()

      // For stress monitor, include training load data
      if type == .stress {
        summaryBarData = try await loadStressSummaryBarData(actor: actor)
      } else {
        summaryBarData = try await actor.fetchSummaryBarData(
          metricTypes: type.metrics.map { $0.rawValue },
          for: Date()
        )
      }
    } catch {
      summaryBarData = nil
    }
  }

  /// Loads summary bar data for the stress monitor, including training load z-scores.
  func loadStressSummaryBarData(actor: DailyMetricSampleModelActor) async throws -> MonitorSummaryBarData? {
    let trainingLoadSummary = await HealthStoreFetcher.shared.fetchTrainingLoadSummary()

    let metricsData = try await actor.fetchSummaryBarData(
      metricTypes: MonitorType.stress.detectionMetrics.map { $0.rawValue },
      for: Date()
    )

    // If no training load data, fall back to metrics-only data
    guard let summary = trainingLoadSummary else {
      return metricsData
    }

    // Convert training load to z-score (10% = 1 z-score)
    let trainingLoadZScore = summary.percentageDifference / 10.0
    var metricZScores = [MetricZScorePoint(metricType: "trainingLoad", zScore: trainingLoadZScore)]

    if let metricsData {
      metricZScores.append(contentsOf: metricsData.metricZScores)
      return MonitorSummaryBarData(
        metricZScores: metricZScores,
        minZScore: min(trainingLoadZScore, metricsData.minZScore),
        maxZScore: max(trainingLoadZScore, metricsData.maxZScore)
      )
    }

    return MonitorSummaryBarData(
      metricZScores: metricZScores,
      minZScore: trainingLoadZScore,
      maxZScore: trainingLoadZScore
    )
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        MiniMonitorCard(type: .recovery, state: .good)
        MiniMonitorCard(type: .stress, state: .attention)
        MiniMonitorCard(type: .sleep, state: .alert)
      }
    }
  }
}
