//
//  TrainingLoadRangeRow.swift
//  Bloom
//

import SwiftUI
import SFSafeSymbols
import CoreHealth
import DataContainer

/// Displays training load data using the MonitorSummaryBar component.
/// Converts TrainingLoadSummary percentage differences to z-scores for display.
struct TrainingLoadRangeRow: View {

  let selectedPeriod: StatTimePeriod

  @State private var trainingLoadSummary: TrainingLoadSummary?
  @State private var summaryBarData7Day: MonitorSummaryBarData?
  @State private var summaryBarData30Day: MonitorSummaryBarData?
  @State private var isLoading = true

  private var summaryBarData: MonitorSummaryBarData? {
    selectedPeriod == .sevenDays ? summaryBarData7Day : summaryBarData30Day
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Header with icon, name, and current value
      HStack(spacing: 10) {
        Image(systemSymbol: .flameFill)
          .font(.body)
          .foregroundStyle(.secondary)
          .frame(width: 24)

        Text("Training Load")
          .font(.subheadline)
          .fontWeight(.medium)

        Spacer()

        if let summary = trainingLoadSummary {
          Text(summary.status.rawValue)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
        } else if isLoading {
          ProgressView()
            .scaleEffect(0.8)
        } else {
          Text("No data")
            .font(.subheadline)
            .foregroundStyle(.tertiary)
        }
      }

      // Range bar
      if let summaryData = summaryBarData {
        MonitorSummaryBar(
          data: summaryData,
          lowLabel: "Below",
          normalLabel: "Steady",
          highLabel: "Above"
        )
      } else {
        // Placeholder bar
        Capsule()
          .fill(Color(.systemGray5))
          .frame(height: 20)
      }
    }
    .task {
      await loadData()
    }
  }

  /// Creates MonitorSummaryBarData for a given number of days from TrainingLoadSummary
  private func createSummaryBarData(summary: TrainingLoadSummary, days: Int) -> MonitorSummaryBarData {
    // Convert percentage difference to z-score (10% = 1 z-score)
    let currentZScore = summary.percentageDifference / 10.0

    // Calculate min/max z-scores from trend data for the period
    let (minZScore, maxZScore) = calculateTrendZScoreRange(summary: summary, days: days)

    return MonitorSummaryBarData(
      metricZScores: [
        MetricZScorePoint(metricType: "trainingLoad", zScore: currentZScore)
      ],
      min7DayZScore: minZScore,
      max7DayZScore: maxZScore
    )
  }

  /// Calculates the min/max z-scores from trend data for a specific number of days
  private func calculateTrendZScoreRange(summary: TrainingLoadSummary, days: Int) -> (min: Double, max: Double) {
    // Compare each day's 7-day average to the corresponding 28-day average
    var zScores: [Double] = []

    // Use only the last N days of trend data
    let trendCount = summary.sevenDayTrend.count
    let startIndex = max(0, trendCount - days)

    for index in startIndex..<trendCount {
      guard index < summary.twentyEightDayTrend.count else { continue }
      let sevenDayPoint = summary.sevenDayTrend[index]
      let twentyEightDayValue = summary.twentyEightDayTrend[index].value

      guard twentyEightDayValue > 0 else { continue }

      // Calculate percentage difference for this day
      let percentDiff = ((sevenDayPoint.value - twentyEightDayValue) / twentyEightDayValue) * 100
      // Convert to z-score
      let zScore = percentDiff / 10.0
      zScores.append(zScore)
    }

    guard !zScores.isEmpty else {
      // Fallback to current value
      let currentZScore = summary.percentageDifference / 10.0
      return (currentZScore, currentZScore)
    }

    return (zScores.min() ?? 0, zScores.max() ?? 0)
  }

  private func loadData() async {
    await TrainingLoadCalculator.shared.refreshTrainingLoad()
    let summary = await TrainingLoadCalculator.shared.trainingLoadSummary

    // Pre-calculate summary bar data on background thread
    let data7Day: MonitorSummaryBarData?
    let data30Day: MonitorSummaryBarData?

    if let summary {
      data7Day = createSummaryBarData(summary: summary, days: 7)
      data30Day = createSummaryBarData(summary: summary, days: 30)
    } else {
      data7Day = nil
      data30Day = nil
    }

    // Only update state on main thread
    await MainActor.run {
      self.trainingLoadSummary = summary
      self.summaryBarData7Day = data7Day
      self.summaryBarData30Day = data30Day
      self.isLoading = false
    }
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    VStack(spacing: 16) {
      TrainingLoadRangeRow(selectedPeriod: .sevenDays)
    }
    .cardContainer()
    .padding()
  }
}
