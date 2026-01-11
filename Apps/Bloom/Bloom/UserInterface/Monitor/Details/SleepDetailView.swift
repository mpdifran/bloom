//
//  SleepDetailView.swift
//  Bloom
//
//  Created by Claude on 2026-01-10.
//

import SwiftUI
import SFSafeSymbols
import TelemetryDeck

/// Detail view for the Sleep Quality & Rhythm monitor.
/// Shows state history, sleep signals, and findings.
struct SleepDetailView: View {

  @State private var selectedPeriod: StatTimePeriod = .sevenDays
  @State private var historicalResults: [MonitorResult] = []
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
          Text("Sleep Quality & Rhythm")
            .font(.headline)
          Text(selectedPeriod == .sevenDays ? "Last 7 Days" : "Last 30 Days")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .navigationTitle("Sleep")
    .navigationBarTitleDisplayMode(.inline)
    .task(id: selectedPeriod) {
      await loadData()
    }
    .onAppear {
      TelemetryDeck.signal("View Sleep Monitor Details")
    }
  }

  // MARK: - Content

  private var contentView: some View {
    BloomScrollView(spacing: 20) {
      periodPicker

      stateHistorySection

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
    MonitorStateChart(results: historicalResults, monitorType: .sleep)
      .cardContainer()
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
      Label("About Sleep Monitoring", systemSymbol: .infoCircle)
        .font(.subheadline)
        .fontWeight(.medium)

      Text("This monitor tracks your sleep patterns including duration, efficiency, and schedule consistency. It detects when your sleep is declining or when your bedtime and wake time are becoming irregular, which can affect your circadian rhythm and overall health.")
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
      systemImage: "moon.fill",
      description: Text("We need more sleep data to show your sleep quality history.")
    )
  }

  // MARK: - Data Loading

  private func loadData() async {
    isLoading = true

    let days = selectedPeriod == .sevenDays ? 7 : 30

    do {
      historicalResults = try await DetectionEngine.shared.calculateHistoricalStates(
        for: .sleep,
        days: days
      )
    } catch {
      // Handle error silently, empty state will show
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
