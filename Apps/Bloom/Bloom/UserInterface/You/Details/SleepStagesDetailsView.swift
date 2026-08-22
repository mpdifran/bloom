//
//  SleepStagesDetailsView.swift
//  Bloom
//
//  Created by Assistant on 2026-01-09.
//

import SwiftUI
import Charts
import TelemetryDeck
import SFSafeSymbols
import CoreHealth
import BloomFoundation
@preconcurrency import HealthKit

struct SleepStagesDetailsView: View {
  @State private var selectedPeriod: StatTimePeriod = .sevenDays
  @State private var sleepStageDataPoints: [SleepStageDataPoint]?
  @State private var sleepAnalysis: SleepAnalysis?
  @State private var stageAverages: SleepStageAverages?

  var body: some View {
    BloomScrollView(spacing: 20) {
      StatTimePeriodPicker(selectedPeriod: $selectedPeriod, includeOneDay: true)

      if hasData {
        contentView
      } else {
        emptyView
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Sleep Stages",
          subtitle: selectedPeriod.displayName
        )
      }
    }
    .navigationTitle("Sleep Stages")
    .navigationBarTitleDisplayMode(.inline)
    .animation(.default, value: sleepStageDataPoints?.map(\.id))
    .animation(.default, value: selectedPeriod)
    .task(id: selectedPeriod) {
      await loadData()
    }
    .onAppear {
      TelemetryDeck.viewScreen("Sleep Stages Details")
    }
  }
}

// MARK: - Data Loading

private extension SleepStagesDetailsView {

  var hasData: Bool {
    if selectedPeriod == .oneDay {
      return sleepAnalysis != nil
    }
    return sleepStageDataPoints?.isNotEmpty ?? false
  }

  func loadData() async {
    if selectedPeriod == .oneDay {
      await loadSingleDayData()
    } else {
      await loadMultiDayData()
    }
  }

  func loadSingleDayData() async {
    let dateRange = selectedPeriod.dateRange
    let analyses = await HealthStoreFetcher.shared.fetchSleepAnalysis(dateRange: dateRange)
    sleepAnalysis = analyses.first
  }

  func loadMultiDayData() async {
    sleepStageDataPoints = await YouStatsCalculator.shared.calculateSleepStageDataPointsForPeriod(selectedPeriod)
    stageAverages = calculateStageAverages()
  }

  func calculateStageAverages() -> SleepStageAverages? {
    guard let dataPoints = sleepStageDataPoints, dataPoints.isNotEmpty else { return nil }

    let calendar = Calendar.current
    var dailyTotals: [Date: [SleepStage: Double]] = [:]

    for dataPoint in dataPoints {
      let day = calendar.startOfDay(for: dataPoint.date)
      dailyTotals[day, default: [:]][dataPoint.stage] = dataPoint.minutes
    }

    guard dailyTotals.isNotEmpty else { return nil }

    let dayCount = Double(dailyTotals.count)
    var stageTotals: [SleepStage: Double] = [:]

    for (_, stages) in dailyTotals {
      for (stage, minutes) in stages {
        stageTotals[stage, default: 0] += minutes
      }
    }

    let avgCore = stageTotals[.core, default: 0] / dayCount
    let avgDeep = stageTotals[.deep, default: 0] / dayCount
    let avgRem = stageTotals[.rem, default: 0] / dayCount
    let avgAwake = stageTotals[.awake, default: 0] / dayCount
    let totalSleep = avgCore + avgDeep + avgRem + avgAwake

    return SleepStageAverages(
      avgCoreMinutes: avgCore,
      avgDeepMinutes: avgDeep,
      avgRemMinutes: avgRem,
      avgAwakeMinutes: avgAwake,
      totalSleepMinutes: totalSleep
    )
  }
}

// MARK: - Content Views

private extension SleepStagesDetailsView {

  @ViewBuilder
  var contentView: some View {
    if selectedPeriod == .oneDay {
      singleDayChartSection
    } else {
      multiDayChartSection
    }

    educationalSection
  }

  var emptyView: some View {
    ContentUnavailableView(
      "No Sleep Data",
      systemImage: "moon.zzz.fill",
      description: Text("Enable Sleep Focus and wear your Apple Watch to bed to track your sleep stages.")
    )
  }
}

// MARK: - Multi-Day Chart

private extension SleepStagesDetailsView {

  var multiDayChartSection: some View {
    VStack(alignment: .leading) {
      VStack {
        VitalDetailChartTitleView(
          title: "Sleep Stages",
          value: stageAverages?.formattedTotalSleep ?? ""
        )
        .padding(.horizontal)
        .padding(.top)

        if let dataPoints = sleepStageDataPoints, dataPoints.isNotEmpty {
          Chart(dataPoints) { dataPoint in
            AreaMark(
              x: .value("Day", dataPoint.date),
              y: .value("Minutes", dataPoint.minutes),
              stacking: .standard
            )
            .foregroundStyle(by: .value("Stage", dataPoint.stage.rawValue))
            .interpolationMethod(.catmullRom)
          }
          .chartForegroundStyleScale([
            SleepStage.core.rawValue: Color.coreSleep,
            SleepStage.deep.rawValue: Color.deepSleep,
            SleepStage.rem.rawValue: Color.remSleep,
            SleepStage.awake.rawValue: Color.awakeSleep
          ])
          .chartXAxis(.hidden)
          .chartYAxis(.hidden)
          .chartLegend(.hidden)
          .chartXScale(domain: chartXDomain)
          .frame(height: 250)
        }
      }
      .cardContainer(includePadding: false)

      DetailInfoCardView {
        Text("This chart shows how your time was distributed across different sleep stages each night. A healthy sleep pattern includes cycles through all stages.")
      }
    }
  }

  var chartXDomain: ClosedRange<Date> {
    guard let dataPoints = sleepStageDataPoints,
          let minDate = dataPoints.map(\.date).min(),
          let maxDate = dataPoints.map(\.date).max() else {
      return Date()...Date()
    }
    return minDate...maxDate
  }
}

// MARK: - Single Day Chart

private extension SleepStagesDetailsView {

  var singleDayChartSection: some View {
    VStack(alignment: .leading) {
      VStack {
        VitalDetailChartTitleView(
          title: "Sleep Timeline",
          value: sleepAnalysis.map { formatDuration($0.overallMinutes) } ?? ""
        )

        if let sleepAnalysis {
          AppleSleepStageChartView(sleepAnalysis: sleepAnalysis)
            .frame(height: 200)
        }
      }
      .cardContainer()

      DetailInfoCardView {
        Text("This timeline shows how you transitioned between sleep stages throughout the night. Your body naturally cycles through these stages multiple times.")
      }
    }
  }
}

// MARK: - Stage Breakdown

private extension SleepStagesDetailsView {

  func stageRow(stage: String, minutes: Double, percentage: Double, color: Color) -> some View {
    HStack(spacing: 8) {
      Capsule()
        .fill(color)
        .frame(width: 6, height: 24)
        .fixedSize()

      VStack(alignment: .leading, spacing: 2) {
        Text(stage)
          .font(.subheadline)
          .bold()
        Text(formatDuration(minutes))
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Text(percentage / 100, format: .percent.precision(.fractionLength(0)))
        .font(.title3)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(color)
    }
    .padding(12)
    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
  }
}

// MARK: - Educational Section

private extension SleepStagesDetailsView {

  var educationalSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      VitalDetailChartTitleView(title: "Understanding Sleep Stages", value: "")

      educationalCard(
        title: "Awake Time",
        icon: .boltHorizontal,
        color: .awakeSleep,
        goal: "Less than 10%",
        goalRange: nil,
        goalMax: 10,
        actualMinutes: stageAverages?.avgAwakeMinutes,
        actualPercentage: stageAverages?.awakePercentage,
        description: "Brief awakenings are normal and often go unremembered. Excessive wake time may indicate sleep disruption."
      )

      educationalCard(
        title: "REM Sleep",
        icon: .eyes,
        color: .remSleep,
        goal: "15-25% of sleep",
        goalRange: 15...25,
        goalMax: nil,
        actualMinutes: stageAverages?.avgRemMinutes,
        actualPercentage: stageAverages?.remPercentage,
        description: "Important for emotional processing, learning, and creativity. REM cycles get longer throughout the night."
      )

      educationalCard(
        title: "Core Sleep",
        icon: .circleDottedCircle,
        color: .coreSleep,
        goal: "45-60% of sleep",
        goalRange: 45...60,
        goalMax: nil,
        actualMinutes: stageAverages?.avgCoreMinutes,
        actualPercentage: stageAverages?.corePercentage,
        description: "Light sleep that serves as a transition between other stages. Still important for brain health and restoration."
      )

      educationalCard(
        title: "Deep Sleep",
        icon: .arrowDownToLine,
        color: .deepSleep,
        goal: "15-25% of sleep",
        goalRange: 15...25,
        goalMax: nil,
        actualMinutes: stageAverages?.avgDeepMinutes,
        actualPercentage: stageAverages?.deepPercentage,
        description: "Essential for physical recovery, immune function, and memory consolidation. Most deep sleep occurs in the first half of the night."
      )
    }
    .cardContainer()
  }

  /// The copy parameters are LocalizedStringKey, not String: a String literal is passed straight
  /// to Text without a catalog lookup, so these cards rendered in English regardless of language.
  func educationalCard(
    title: LocalizedStringKey,
    icon: SFSymbol,
    color: Color,
    goal: LocalizedStringKey,
    goalRange: ClosedRange<Double>?,
    goalMax: Double?,
    actualMinutes: Double?,
    actualPercentage: Double?,
    description: LocalizedStringKey
  ) -> some View {
    let goalMet: Bool = {
      guard let actual = actualPercentage else { return false }
      // Truncate to match displayed value (Int(20.7) = 20, displays as "20%")
      let displayed = Int(actual)
      if let range = goalRange {
        return displayed >= Int(range.lowerBound) && displayed <= Int(range.upperBound)
      }
      if let max = goalMax {
        return Double(displayed) < max
      }
      return false
    }()

    return VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Image(systemSymbol: icon)
          .foregroundStyle(color)
          .font(.title3)

        Text(title)
          .font(.headline)

        Spacer()

        Text(goal)
          .font(.caption)
          .foregroundStyle(.white)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background {
            if goalMet {
              Capsule().fill(color)
            } else {
              Capsule().fill(color.tertiary)
                .overlay {
                  Capsule()
                    .strokeBorder(color, style: StrokeStyle(lineWidth: 1, dash: [4]))
                }
            }
          }
      }

      HStack(alignment: .bottom) {
        Text(description)
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Spacer()

        if let percentage = actualPercentage {
          VStack(alignment: .trailing, spacing: 0) {
            if let minutes = actualMinutes {
              Text(formatDuration(minutes))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Text(percentage / 100, format: .percent.precision(.fractionLength(0)))
              .font(.largeTitle)
              .bold()
              .fontDesign(.rounded)
              .foregroundStyle(goalMet ? color : .secondary)
          }
        }
      }
    }
    .padding(12)
    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
  }
}

// MARK: - Helpers

private extension SleepStagesDetailsView {

  func formatMinutes(_ minutes: Double) -> String {
    // Locale-aware duration: hand-built "3h 45m" hardcoded English unit abbreviations.
    let hours = Int(minutes) / 60
    if hours > 0 {
      return Duration.seconds(hours * 3600).formatted(.units(allowed: [.hours], width: .narrow))
    }
    return Duration.seconds(Int(minutes) * 60).formatted(.units(allowed: [.minutes], width: .narrow))
  }

  func formatDuration(_ minutes: Double) -> String {
    // Locale-aware duration: hand-built "3h 45m" hardcoded English unit abbreviations.
    Duration.seconds(Int(minutes) * 60)
      .formatted(.units(allowed: [.hours, .minutes], width: .narrow))
  }
}

// MARK: - Data Model

private struct SleepStageAverages {
  let avgCoreMinutes: Double
  let avgDeepMinutes: Double
  let avgRemMinutes: Double
  let avgAwakeMinutes: Double
  let totalSleepMinutes: Double

  var formattedTotalSleep: String {
    // Locale-aware duration: hand-built "3h 45m" hardcoded English unit abbreviations.
    return Duration.seconds(Int(totalSleepMinutes) * 60)
      .formatted(.units(allowed: [.hours, .minutes], width: .narrow))
  }

  var corePercentage: Double {
    totalSleepMinutes > 0 ? (avgCoreMinutes / totalSleepMinutes) * 100 : 0
  }

  var deepPercentage: Double {
    totalSleepMinutes > 0 ? (avgDeepMinutes / totalSleepMinutes) * 100 : 0
  }

  var remPercentage: Double {
    totalSleepMinutes > 0 ? (avgRemMinutes / totalSleepMinutes) * 100 : 0
  }

  var awakePercentage: Double {
    totalSleepMinutes > 0 ? (avgAwakeMinutes / totalSleepMinutes) * 100 : 0
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      SleepStagesDetailsView()
    }
  }
}
