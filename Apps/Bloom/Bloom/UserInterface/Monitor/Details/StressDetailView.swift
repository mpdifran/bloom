//
//  StressDetailView.swift
//  Bloom
//
//  Created by Claude on 2026-01-10.
//

import SwiftUI
import SFSafeSymbols
import TelemetryDeck
import DataContainer
import BloomUI

/// Detail view for the Stress & Workout Load monitor.
/// Shows state history, training load signals, and findings.
struct StressDetailView: View {

  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared

  @State private var selectedPeriod: StatTimePeriod = .sevenDays
  @State private var historicalResults7Day: [MonitorResult] = []
  @State private var historicalResults30Day: [MonitorResult] = []
  @State private var rangeData7Day: [MetricRangeData] = []
  @State private var rangeData30Day: [MetricRangeData] = []

  private var historicalResults: [MonitorResult] {
    selectedPeriod == .sevenDays ? historicalResults7Day : historicalResults30Day
  }

  private var rangeData: [MetricRangeData] {
    selectedPeriod == .sevenDays ? rangeData7Day : rangeData30Day
  }

  /// The current (most recent) result
  private var currentResult: MonitorResult? {
    historicalResults.last
  }

  var body: some View {
    contentView
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text("Stress & Workout Load")
          .font(.headline)
      }
      ToolbarItem(placement: .topBarTrailing) {
        Picker("Time Period", selection: $selectedPeriod.animation(.easeInOut(duration: 0.2))) {
          Text("7D").tag(StatTimePeriod.sevenDays)
          Text("30D").tag(StatTimePeriod.oneMonth)
        }
        .pickerStyle(.segmented)
        .fixedSize()
      }
      .hiddenSharedBackground()
    }
    .navigationTitle("Stress")
    .navigationBarTitleDisplayMode(.inline)
    .sensoryFeedback(.selection, trigger: selectedPeriod)
    .task {
      await loadAllData()
    }
    .onAppear {
      TelemetryDeck.signal("View Stress Monitor Details")
    }
  }

  // MARK: - Content

  private var contentView: some View {
    BloomScrollView(spacing: 20) {
      stateHistorySection

      if let currentResult {
        MonitorInsightCard(
          monitorType: .stress,
          currentResult: currentResult
        )
      }

      metricRangesSection

      if let result = currentResult, !result.findings.isEmpty {
        findingsSection(result: result)
      }

      infoCard

      if !aiFeatureSettings.monitorEnabled {
        MonitorPrivacyAIFeatureOptInCell()
          .cardContainer()
      }
    }
    .onChange(of: aiFeatureSettings.monitorEnabled) {
      Task {
        await ConsentManager.shared.syncGranularConsentSilently()
      }
    }
  }

  // MARK: - State History

  private var stateHistorySection: some View {
    MonitorStateChart(monitorType: .stress, days: selectedPeriod == .sevenDays ? 7 : 30)
      .cardContainer()
  }

  // MARK: - Metric Ranges

  private var metricRangesSection: some View {
    let metrics = MonitorType.stress.detectionMetrics

    return VStack(alignment: .leading, spacing: 12) {
      Text(selectedPeriod == .sevenDays ? "7-Day Ranges" : "30-Day Ranges")
        .font(.headline)
        .padding(.horizontal)

      VStack(spacing: 16) {
        // Training Load (from workouts)
        TrainingLoadRangeRow(selectedPeriod: selectedPeriod)

        if !metrics.isEmpty {
          Divider()
        }

        // Other metrics (Heart Rate Recovery, etc.)
        ForEach(metrics, id: \.rawValue) { metricType in
          let data = rangeData.first { $0.metricType == metricType.rawValue }
            ?? MetricRangeData(
              metricType: metricType.rawValue,
              displayName: metricType.displayName,
              currentValue: nil,
              min7Day: nil,
              max7Day: nil,
              baseline28Day: nil,
              zScore: nil,
              min7DayZScore: nil,
              max7DayZScore: nil
            )
          MetricRangeRow(rangeData: data, metricType: metricType)
          if metricType != metrics.last {
            Divider()
          }
        }
      }
      .animation(.easeInOut(duration: 0.3), value: rangeData.map(\.metricType))
      .cardContainer()
    }
  }

  // MARK: - Findings

  private func findingsSection(result: MonitorResult) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("What This Means")
        .font(.headline)
        .padding(.horizontal)

      VStack(spacing: 12) {
        ForEach(result.findings) { finding in
          MonitorFindingCell(finding: finding)
        }
      }
      .cardContainer()
    }
  }

  // MARK: - Info Card

  private var infoCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("About Workout Load Monitoring")
        .font(.headline)
        .fontWeight(.medium)

      Text("This monitor tracks your training load using Apple's Workout Effort Scores. It compares your recent 7-day training load to your 28-day average to help you avoid overtraining or detraining. HRV trends and recovery metrics are also considered when available.")
        .font(.body)
        .foregroundStyle(.secondary)
    }
    .horizontalAlignment(.leading)
    .cardContainer()
  }

  // MARK: - Data Loading

  private func loadAllData() async {
    let metrics: [(type: String, displayName: String)] = MonitorType.stress.detectionMetrics.map {
      ($0.rawValue, $0.displayName)
    }

    // Load both periods in parallel, collecting results
    let results = await withTaskGroup(
      of: (Int, [MonitorResult], [MetricRangeData]).self
    ) { group -> [(Int, [MonitorResult], [MetricRangeData])] in
      // Load 7-day data
      group.addTask {
        do {
          let results = try await DetectionEngine.shared.calculateHistoricalStates(for: .stress, days: 7)
          let actor = DailyMetricSampleModelActor.standard()
          let range = try await actor.fetchAllRangeData(metricTypes: metrics, for: Date(), days: 7)
          return (7, results, range)
        } catch {
          return (7, [], [])
        }
      }

      // Load 30-day data
      group.addTask {
        do {
          let results = try await DetectionEngine.shared.calculateHistoricalStates(for: .stress, days: 30)
          let actor = DailyMetricSampleModelActor.standard()
          let range = try await actor.fetchAllRangeData(metricTypes: metrics, for: Date(), days: 30)
          return (30, results, range)
        } catch {
          return (30, [], [])
        }
      }

      var collected: [(Int, [MonitorResult], [MetricRangeData])] = []
      for await result in group {
        collected.append(result)
      }
      return collected
    }

    // Update state only after both complete
    for (days, historicalResults, rangeData) in results {
      if days == 7 {
        historicalResults7Day = historicalResults
        rangeData7Day = rangeData
      } else {
        historicalResults30Day = historicalResults
        rangeData30Day = rangeData
      }
    }
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    NavigationStack {
      StressDetailView()
    }
  }
}
