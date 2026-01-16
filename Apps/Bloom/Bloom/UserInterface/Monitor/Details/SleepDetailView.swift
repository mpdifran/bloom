//
//  SleepDetailView.swift
//  Bloom
//
//  Created by Claude on 2026-01-10.
//

import SwiftUI
import SFSafeSymbols
import TelemetryDeck
import DataContainer

/// Detail view for the Sleep Quality & Rhythm monitor.
/// Shows state history, sleep signals, and findings.
struct SleepDetailView: View {

  @State private var selectedPeriod: StatTimePeriod = .sevenDays
  @State private var historicalResults7Day: [MonitorResult] = []
  @State private var historicalResults30Day: [MonitorResult] = []
  @State private var rangeData7Day: [MetricRangeData] = []
  @State private var rangeData30Day: [MetricRangeData] = []
  @State private var isLoading = false

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
    Group {
      if isLoading && historicalResults7Day.isEmpty {
        loadingView
      } else if historicalResults7Day.isEmpty {
        emptyView
      } else {
        contentView
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text("Sleep Quality & Rhythm")
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
    .navigationTitle("Sleep")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await loadAllData()
    }
    .onAppear {
      TelemetryDeck.signal("View Sleep Monitor Details")
    }
  }

  // MARK: - Content

  private var contentView: some View {
    BloomScrollView(spacing: 20) {
      stateHistorySection

      if !rangeData.isEmpty {
        metricRangesSection
      }

      if let result = currentResult, !result.findings.isEmpty {
        findingsSection(result: result)
      }

      infoCard
    }
  }

  // MARK: - State History

  private var stateHistorySection: some View {
    MonitorStateChart(monitorType: .sleep, days: selectedPeriod == .sevenDays ? 7 : 30)
      .cardContainer()
  }

  // MARK: - Metric Ranges

  private var metricRangesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(selectedPeriod == .sevenDays ? "7-Day Ranges" : "30-Day Ranges")
        .font(.headline)
        .padding(.horizontal)

      VStack(spacing: 16) {
        ForEach(rangeData) { data in
          if let metricType = MonitorMetricType(rawValue: data.metricType) {
            MetricRangeRow(rangeData: data, metricType: metricType)
            if data.id != rangeData.last?.id {
              Divider()
            }
          }
        }
      }
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
      .horizontalAlignment(.leading)
      .cardContainer()
    }
  }

  // MARK: - Info Card

  private var infoCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("About Sleep Monitoring")
        .font(.headline)
        .fontWeight(.medium)

      Text("This monitor tracks your sleep patterns including duration, efficiency, and schedule consistency. It detects when your sleep is declining or when your bedtime and wake time are becoming irregular, which can affect your circadian rhythm and overall health.")
        .font(.body)
        .foregroundStyle(.secondary)
    }
    .horizontalAlignment(.leading)
    .cardContainer()
  }

  // MARK: - Loading

  private var loadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.5)

      Text("Loading history...")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Empty

  private var emptyView: some View {
    ContentUnavailableView(
      "No History Available",
      systemImage: "moon.fill",
      description: Text("We need more sleep data to show your sleep quality history.")
    )
  }

  // MARK: - Data Loading

  private func loadAllData() async {
    isLoading = true

    let metrics: [(type: String, displayName: String)] = MonitorType.sleep.metrics.map {
      ($0.rawValue, $0.displayName)
    }

    // Load both periods in parallel, collecting results
    let results = await withTaskGroup(
      of: (Int, [MonitorResult], [MetricRangeData]).self
    ) { group -> [(Int, [MonitorResult], [MetricRangeData])] in
      // Load 7-day data
      group.addTask {
        do {
          let results = try await DetectionEngine.shared.calculateHistoricalStates(for: .sleep, days: 7)
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
          let results = try await DetectionEngine.shared.calculateHistoricalStates(for: .sleep, days: 30)
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

    isLoading = false
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    NavigationStack {
      SleepDetailView()
    }
  }
}
