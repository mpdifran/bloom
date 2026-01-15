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

/// Detail view for the Stress & Workout Load monitor.
/// Shows state history, training load signals, and findings.
struct StressDetailView: View {

  @State private var selectedPeriod: StatTimePeriod = .sevenDays
  @State private var historicalResults: [MonitorResult] = []
  @State private var rangeData: [MetricRangeData] = []
  @State private var isLoading = false

  /// The current (most recent) result
  private var currentResult: MonitorResult? {
    historicalResults.last
  }

  var body: some View {
    Group {
      if isLoading && historicalResults.isEmpty {
        loadingView
      } else if historicalResults.isEmpty {
        emptyView
      } else {
        contentView
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VStack(spacing: 2) {
          Text("Stress & Workout Load")
            .font(.headline)
          Text(selectedPeriod == .sevenDays ? "Last 7 Days" : "Last 30 Days")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .navigationTitle("Stress")
    .navigationBarTitleDisplayMode(.inline)
    .task(id: selectedPeriod) {
      await loadData()
    }
    .onAppear {
      TelemetryDeck.signal("View Stress Monitor Details")
    }
  }

  // MARK: - Content

  private var contentView: some View {
    BloomScrollView(spacing: 20) {
      periodPicker

      stateHistorySection

      if !rangeData.isEmpty {
        metricRangesSection
      }

      if let result = currentResult {
        if !result.signals.isEmpty {
          signalsSection(result: result)
        }

        if !result.findings.isEmpty {
          findingsSection(result: result)
        }
      }

      infoCard
    }
  }

  // MARK: - Period Picker

  private var periodPicker: some View {
    Picker("Time Period", selection: $selectedPeriod) {
      Text("7 Days").tag(StatTimePeriod.sevenDays)
      Text("30 Days").tag(StatTimePeriod.oneMonth)
    }
    .pickerStyle(.segmented)
    .padding(.horizontal)
  }

  // MARK: - State History

  private var stateHistorySection: some View {
    MonitorStateChart(results: historicalResults, monitorType: .stress)
      .cardContainer()
  }

  // MARK: - Metric Ranges

  private var metricRangesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("7-Day Ranges")
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

  // MARK: - Signals

  private func signalsSection(result: MonitorResult) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Current Signals")
        .font(.headline)
        .padding(.horizontal)

      VStack(spacing: 8) {
        ForEach(result.signals) { signal in
          MetricSignalRow(signal: signal)
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
      .cardContainer()
    }
  }

  // MARK: - Info Card

  private var infoCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label("About Workout Load Monitoring", systemSymbol: .infoCircle)
        .font(.subheadline)
        .fontWeight(.medium)

      Text("This monitor tracks your training load balance using the acute:chronic workload ratio. It compares your recent 7-day activity to your 28-day average to help you avoid overtraining or detraining. HRV trends are also considered when available.")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
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
      systemImage: "flame.fill",
      description: Text("We need more activity data to show your workout load history.")
    )
  }

  // MARK: - Data Loading

  private func loadData() async {
    isLoading = true

    let days = selectedPeriod == .sevenDays ? 7 : 30

    do {
      historicalResults = try await DetectionEngine.shared.calculateHistoricalStates(
        for: .stress,
        days: days
      )
    } catch {
      // Handle error silently, empty state will show
    }

    // Load range data for stress metrics
    await loadRangeData()

    isLoading = false
  }

  private func loadRangeData() async {
    let metrics: [(type: String, displayName: String)] = MonitorType.stress.metrics.map {
      ($0.rawValue, $0.displayName)
    }

    do {
      let actor = DailyMetricSampleModelActor.standard()
      rangeData = try await actor.fetchAllRangeData(metricTypes: metrics, for: Date())
    } catch {
      // Handle error silently
      rangeData = []
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
