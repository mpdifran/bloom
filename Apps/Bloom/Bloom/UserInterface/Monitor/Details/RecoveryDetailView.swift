//
//  RecoveryDetailView.swift
//  Bloom
//
//  Created by Claude on 2026-01-10.
//

import SwiftUI
import SFSafeSymbols
import TelemetryDeck

/// Detail view for the Recovery & Sickness monitor.
/// Shows state history, current signals, and findings.
struct RecoveryDetailView: View {

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
          Text("Recovery & Sickness")
            .font(.headline)
          Text(selectedPeriod == .sevenDays ? "Last 7 Days" : "Last 30 Days")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .navigationTitle("Recovery")
    .navigationBarTitleDisplayMode(.inline)
    .task(id: selectedPeriod) {
      await loadData()
    }
    .onAppear {
      TelemetryDeck.signal("View Recovery Monitor Details")
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
    MonitorStateChart(results: historicalResults, monitorType: .recovery)
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
      Label("About Recovery Monitoring", systemSymbol: .infoCircle)
        .font(.subheadline)
        .fontWeight(.medium)

      Text("This monitor tracks early physiological signs that may indicate your body is fighting off illness or needs extra recovery time. It analyzes your resting heart rate, heart rate variability, wrist temperature, and respiratory rate to detect subtle changes from your personal baseline.")
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
      systemImage: "heart.fill",
      description: Text("We need more health data to show your recovery history.")
    )
  }

  // MARK: - Data Loading

  private func loadData() async {
    isLoading = true

    let days = selectedPeriod == .sevenDays ? 7 : 30

    do {
      historicalResults = try await DetectionEngine.shared.calculateHistoricalStates(
        for: .recovery,
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
      RecoveryDetailView()
    }
  }
}
