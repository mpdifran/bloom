//
//  YearInBloomSleepStagesCard.swift
//  Bloom
//
//  Created by Claude on 2025-12-16.
//

import SwiftUI
import Charts
import CoreHealth
import BloomUI

struct YearInBloomSleepStagesCard: View {
  let stats: YearInBloomSleepStats

  @State private var selectedMonth: MonthlySleepStageChartData?

  var body: some View {
    YearInBloomCard(
      title: "Sleep Stages",
      focusStat: formattedAverageSleepDuration,
      focusStatLabel: "Avg Duration",
      includePadding: false,
      includeDivider: false,
      backgroundFill: .background.secondary
    ) {
      VStack(spacing: 16) {
        sleepStagesChart
        scoreStatView
        sleepScheduleChart
      }
      .padding(.bottom)
    }
  }
}

// MARK: - Chart

private extension YearInBloomSleepStagesCard {

  var sleepStagesChart: some View {
    Chart(sleepStageDataPoints) { dataPoint in
      AreaMark(
        x: .value("Month", dataPoint.date),
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
    .chartXScale(domain: yearStart...yearEnd)
    .chartYScale(domain: 0...sleepStagesYMax)
    .chartLegend(.hidden)
    .chartOverlay { proxy in
      GeometryReader { geometry in
        Rectangle()
          .fill(.clear)
          .contentShape(Rectangle())
          .gesture(
            DragGesture(minimumDistance: 0)
              .onChanged { value in
                let xPosition = value.location.x
                if let date: Date = proxy.value(atX: xPosition) {
                  selectedMonth = findNearestMonth(to: date)
                }
              }
              .onEnded { _ in
                selectedMonth = nil
              }
          )

        // Annotation overlay
        if let selected = selectedMonth,
           let xPosition = proxy.position(forX: selected.date) {
          VStack(alignment: .leading, spacing: 2) {
            Text(monthName(for: selected.date))
              .font(.caption2)
              .bold()
            HStack(spacing: 4) {
              Circle().fill(Color.coreSleep).frame(width: 6, height: 6)
              Text("Core: \(selected.coreMinutesDisplay)m")
            }
            HStack(spacing: 4) {
              Circle().fill(Color.deepSleep).frame(width: 6, height: 6)
              Text("Deep: \(selected.deepMinutesDisplay)m")
            }
            HStack(spacing: 4) {
              Circle().fill(Color.remSleep).frame(width: 6, height: 6)
              Text("REM: \(selected.remMinutesDisplay)m")
            }
            HStack(spacing: 4) {
              Circle().fill(Color.awakeSleep).frame(width: 6, height: 6)
              Text("Awake: \(selected.awakeMinutesDisplay)m")
            }
          }
          .font(.caption2)
          .padding(8)
          .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
          .position(x: min(max(xPosition, 60), geometry.size.width - 60), y: geometry.size.height / 2)
          .environment(\.colorScheme, .dark)
        }
      }
    }
    .frame(height: 140)
    .sensoryFeedback(.selection, trigger: selectedMonth)
  }

  var sleepScheduleChart: some View {
    Chart(sleepScheduleData) { data in
      RectangleMark(
        x: .value("Month", data.date),
        yStart: .value("Wake", data.wakeTimeMinutes),
        yEnd: .value("Bedtime", data.bedtimeMinutes),
        width: 16
      )
      .foregroundStyle(Color.deepSleep.gradient)
      .cornerRadius(4)
    }
    .chartXAxis {
      AxisMarks(values: .stride(by: .month)) { _ in
        AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
      }
    }
    .chartYAxis {
      AxisMarks(values: scheduleYAxisValues) { value in
        AxisGridLine()
          .foregroundStyle(.secondary.opacity(0.3))
        if let minutes = value.as(Double.self) {
          AxisValueLabel {
            Text(formatCompactTime(minutes))
              .font(.caption2)
          }
        }
      }
    }
    .chartXScale(domain: scheduleXStart...scheduleXEnd)
    .chartYScale(domain: scheduleYMin...scheduleYMax)
    .frame(height: 160)
    .padding(.horizontal)
  }

  /// Convert minutes from noon to display time (e.g., 480 -> "8PM", 720 -> "12AM")
  func formatCompactTime(_ minutesFromNoon: Double) -> String {
    // Convert back to minutes from midnight
    var minutesFromMidnight = minutesFromNoon + 720
    if minutesFromMidnight >= 1440 {
      minutesFromMidnight -= 1440
    }
    let hours = Int(minutesFromMidnight) / 60
    let period = hours >= 12 ? "PM" : "AM"
    let displayHour = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours)
    return "\(displayHour)\(period)"
  }

  var legendView: some View {
    HStack(spacing: 12) {
      sleepStageLegendItem(color: .coreSleep, label: "Core")
      sleepStageLegendItem(color: .deepSleep, label: "Deep")
      sleepStageLegendItem(color: .remSleep, label: "REM")
      sleepStageLegendItem(color: .awakeSleep, label: "Awake")
      Spacer()
    }
    .font(.caption2)
    .fontDesign(.rounded)
    .padding(.top, 8)
  }

  func sleepStageLegendItem(color: Color, label: String) -> some View {
    HStack(spacing: 4) {
      Circle()
        .fill(color)
        .frame(width: 8, height: 8)
      Text(label)
    }
  }

  func findNearestMonth(to date: Date) -> MonthlySleepStageChartData? {
    let calendar = Calendar.current
    let targetMonth = calendar.component(.month, from: date)
    return monthlyChartData.first { data in
      calendar.component(.month, from: data.date) == targetMonth
    }
  }

  func monthName(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    return formatter.string(from: date)
  }

  var scoreStatView: some View {
    HStack {
      if let lowest = stats.lowestSleepScore {
        HStack {
          Image(systemSymbol: .moonsetFill)
            .foregroundStyle(.awakeSleep)
            .font(.title)
          VStack(alignment: .leading, spacing: 0) {
            Text("\(lowest.score)")
              .font(.title)
            Text("Lowest Score")
              .font(.caption)
          }
          Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .cardContainer(fill: .thickMaterial, includePadding: false)
      }

      if let highest = stats.highestSleepScore {
        HStack {
          Image(systemSymbol: .moonriseFill)
            .foregroundStyle(.coreSleep)
            .font(.title)
          VStack(alignment: .leading, spacing: 0) {
            Text("\(highest.score)")
              .font(.title)
            Text("Highest Score")
              .font(.caption)
          }
          Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .cardContainer(fill: .thickMaterial, includePadding: false)
      }
    }
    .font(.headline)
    .bold()
    .fontDesign(.rounded)
    .padding(.horizontal)
  }
}

// MARK: - Helpers

private extension YearInBloomSleepStagesCard {

  var formattedAverageSleepDuration: String {
    let totalMinutes = stats.yearTotals.averageSleepDurationMinutes
    let hours = Int(totalMinutes) / 60
    let minutes = Int(totalMinutes) % 60
    return "\(hours)h \(minutes)m"
  }

  var monthlyChartData: [MonthlySleepStageChartData] {
    stats.monthlySleepStageData()
  }

  var sleepStageDataPoints: [SleepStageDataPoint] {
    stats.sleepStageDataPoints()
  }

  var yearStart: Date {
    Calendar.current.date(from: DateComponents(year: stats.year, month: 1, day: 15))!
  }

  var yearEnd: Date {
    Calendar.current.date(from: DateComponents(year: stats.year, month: 12, day: 15))!
  }

  var sleepScheduleData: [MonthlySleepScheduleData] {
    stats.monthlySleepScheduleData()
  }

  var sleepStagesYMax: Double {
    let maxTotalMinutes = monthlyChartData.map(\.totalMinutes).max() ?? 480
    return maxTotalMinutes + 30
  }

  var scheduleYMin: Double {
    let minBedtime = sleepScheduleData.map(\.bedtimeMinutes).min() ?? 600
    return minBedtime - 30
  }

  var scheduleYMax: Double {
    let maxWakeTime = sleepScheduleData.map(\.wakeTimeMinutes).max() ?? 1200
    return maxWakeTime + 30
  }

  /// Generate Y-axis tick values at 4-hour intervals within the data range
  var scheduleYAxisValues: [Double] {
    let interval = 240.0 // 4 hours in minutes
    let firstTick = (ceil(scheduleYMin / interval) * interval)
    let lastTick = (floor(scheduleYMax / interval) * interval)
    var values: [Double] = []
    var tick = firstTick
    while tick <= lastTick {
      values.append(tick)
      tick += interval
    }
    return values
  }

  var scheduleXStart: Date {
    Calendar.current.date(from: DateComponents(year: stats.year - 1, month: 12, day: 15))!
  }

  var scheduleXEnd: Date {
    Calendar.current.date(from: DateComponents(year: stats.year + 1, month: 1, day: 15))!
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      YearInBloomSleepStagesCard(
        stats: .preview
      )
    }
  }
}
