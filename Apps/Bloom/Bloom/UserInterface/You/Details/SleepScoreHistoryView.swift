//
//  SleepScoreHistoryView.swift
//  Bloom
//
//  Created by Assistant on 2026-01-09.
//

import SwiftUI
import Charts
import TelemetryDeck
import SFSafeSymbols
import CoreHealth

struct SleepScoreHistoryView: View {
  @State private var selectedPeriod: StatTimePeriod = .sevenDays
  @State private var sleepAnalyses: [SleepAnalysis] = []

  var body: some View {
    Group {
      if sleepAnalyses.isNotEmpty {
        contentView
      } else {
        emptyView
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Sleep Score",
          subtitle: selectedPeriod.displayName
        )
      }
    }
    .navigationTitle("Sleep Score")
    .navigationBarTitleDisplayMode(.inline)
    .animation(.default, value: sleepAnalyses.map(\.id))
    .task(id: selectedPeriod) {
      await loadData()
    }
    .onAppear {
      TelemetryDeck.viewScreen("Sleep Score Details")
    }
  }
}

// MARK: - Data Loading

private extension SleepScoreHistoryView {

  func loadData() async {
    let dateRange = selectedPeriod.dateRange
    let analyses = await HealthStoreFetcher.shared.fetchSleepAnalysis(dateRange: dateRange)
    sleepAnalyses = analyses.sorted { $0.endDate > $1.endDate }
  }

  var averageScore: Int? {
    guard sleepAnalyses.isNotEmpty else { return nil }
    let total = sleepAnalyses.map(\.overallScore).reduce(0, +)
    return total / sleepAnalyses.count
  }

  var chartDataPoints: [ScoreDataPoint] {
    if selectedPeriod.aggregatesByWeek {
      return aggregatedByWeek()
    } else {
      return sleepAnalyses.map { ScoreDataPoint(date: $0.endDate, score: $0.overallScore) }
        .sorted { $0.date < $1.date }
    }
  }

  func aggregatedByWeek() -> [ScoreDataPoint] {
    let calendar = Calendar.current
    var weeklyData = [Date: [Int]]()

    for analysis in sleepAnalyses {
      let weekStart = calendar.dateInterval(of: .weekOfYear, for: analysis.endDate)?.start ?? analysis.endDate
      weeklyData[weekStart, default: []].append(analysis.overallScore)
    }

    return weeklyData.map { weekStart, scores in
      let avg = scores.reduce(0, +) / scores.count
      return ScoreDataPoint(date: weekStart, score: avg)
    }.sorted { $0.date < $1.date }
  }
}

// MARK: - Content Views

private extension SleepScoreHistoryView {

  var contentView: some View {
    BloomScrollView(spacing: 20) {
      StatTimePeriodPicker(selectedPeriod: $selectedPeriod)

      scoreHistoryChart
      recentNightsSection
    }
  }

  var emptyView: some View {
    ContentUnavailableView(
      "No Sleep Data",
      systemImage: "moon.zzz.fill",
      description: Text("Enable Sleep Focus and wear your Apple Watch to bed to track your sleep score.")
    )
  }
}

// MARK: - Score History Chart

private extension SleepScoreHistoryView {

  var scoreHistoryChart: some View {
    VStack(alignment: .leading) {
      VStack {
        VitalDetailChartTitleView(
          title: "Score History",
          value: averageScore.map { "\($0) avg" } ?? ""
        )

        Chart(chartDataPoints) { dataPoint in
          BarMark(
            x: .value("Date", dataPoint.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
            y: .value("Score", dataPoint.score)
          )
          .foregroundStyle(color(for: dataPoint.score))
          .cornerRadius(4)
        }
        .chartXAxis {
          AxisMarks(values: .automatic) { _ in
            AxisGridLine()
            AxisValueLabel(format: selectedPeriod.chartDateFormat)
          }
        }
        .chartYAxis {
          AxisMarks(values: [0, 25, 50, 75, 100]) { value in
            AxisGridLine()
              .foregroundStyle(.secondary.opacity(0.3))
            if let score = value.as(Int.self) {
              AxisValueLabel {
                Text(verbatim: "\(score)")
                  .font(.caption2)
              }
            }
          }
        }
        .chartYScale(domain: 0...100)
        .chartXScale(domain: chartXDomain)
        .frame(height: 200)
      }
      .cardContainer()

      DetailInfoCardView {
        Text("Your sleep score is calculated based on sleep duration, time spent in each sleep stage, awake time, and heart rate during sleep. A score of 70 or higher indicates good quality sleep.")
      }
    }
  }

  var chartXDomain: ClosedRange<Date> {
    guard let minDate = chartDataPoints.map(\.date).min(),
          let maxDate = chartDataPoints.map(\.date).max() else {
      return Date()...Date()
    }
    return minDate...maxDate
  }
}

// MARK: - Recent Nights Section

private extension SleepScoreHistoryView {

  var recentNightsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      VitalDetailChartTitleView(title: "Recent Nights", value: "")
        .padding(.horizontal)

      ForEach(sleepAnalyses) { analysis in
        NavigationLink {
          SleepDayView(initialDate: analysis.endDate)
        } label: {
          sleepAnalysisCell(analysis)
        }
        .buttonStyle(.plain)
      }
    }
  }

  func sleepAnalysisCell(_ analysis: SleepAnalysis) -> some View {
    HStack(spacing: 12) {
      SleepScoreView(score: analysis.overallScore, isMini: true)

      VStack(alignment: .leading, spacing: 4) {
        Text(analysis.endDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
          .font(.headline)

        Text(formatTimeRange(analysis))
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Text(formatDuration(analysis.overallMinutes))
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .fontDesign(.rounded)

      Spacer()

      Image(systemSymbol: .chevronRight)
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
    .cardContainer()
  }
}

// MARK: - Helpers

private extension SleepScoreHistoryView {

  func formatDuration(_ minutes: Double) -> String {
    // Locale-aware duration: hand-built "3h 45m" hardcoded English unit abbreviations.
    Duration.seconds(Int(minutes) * 60)
      .formatted(.units(allowed: [.hours, .minutes], width: .narrow))
  }

  func formatTimeRange(_ analysis: SleepAnalysis) -> String {
    let bedtime = analysis.startDate.formatted(date: .omitted, time: .shortened)
    let wakeTime = analysis.endDate.formatted(date: .omitted, time: .shortened)
    return "\(bedtime) → \(wakeTime)"
  }

  func color(for sleepScore: Int) -> Color {
    SleepVitalsMonthlySummary.SleepQuality(sleepScore: Double(sleepScore)).color
  }
}

// MARK: - Data Model

private struct ScoreDataPoint: Identifiable {
  let date: Date
  let score: Int

  var id: Date { date }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      SleepScoreHistoryView()
    }
  }
}
