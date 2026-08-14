//
//  SleepStoryPage.swift
//  Bloom
//
//  Created by Claude on 2025-12-18.
//

import SwiftUI
import Charts
import CoreHealth
import BloomUI
import SFSafeSymbols

struct SleepStoryPage: View {
  let stats: YearInBloomSleepStats

  @State private var selectedMonth: MonthlySleepStageChartData?
  @State private var rawSelectedDate: Date?
  @State private var selectedSchedule: MonthlySleepScheduleData?
  @State private var rawScheduleSelectedDate: Date?

  var body: some View {
    VStack {
      Spacer()

      sleepScheduleChart

      scoreStatView

      Spacer()

      Image(systemSymbol: .moonZzzFill)
        .foregroundStyle(.mutedYellow)
        .font(.system(size: 50))
        .contentTransition(.symbolEffect)
        .padding(.bottom)

      focusSentence
        .font(.title)
        .fontWeight(.bold)
        .fontDesign(.rounded)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)

      Spacer()

      sleepStagesChart
    }
    .background {
      Rectangle()
        .fill(.background.secondary)
        .ignoresSafeArea()
    }
    .ignoresSafeArea(edges: [.horizontal, .bottom])
    .toolbar {
      ToolbarItem(placement: .principal) {
        titleView
      }
    }
    .environment(\.colorScheme, .dark)
  }

  private var focusSentence: Text {
    let duration = Text(formattedSleepDuration).foregroundStyle(.coreSleep)

    return Text(
      "You averaged \(duration) of sleep per night.",
      comment: "Year in Bloom sleep summary. The placeholder is an average nightly sleep duration."
    )
  }
}

// MARK: - Charts

private extension SleepStoryPage {

  var titleView: some View {
    Text("Sleep")
      .font(.title3)
      .fontDesign(.rounded)
      .bold()
  }

  var sleepScheduleChart: some View {
    Chart(sleepScheduleData) { data in
      RectangleMark(
        x: .value("Month", data.date),
        yStart: .value("Bedtime", -data.bedtimeMinutes),
        yEnd: .value("Wake", -data.wakeTimeMinutes),
        width: 16
      )
      .foregroundStyle(
        LinearGradient(
          colors: [.deepSleep, .coreSleep, .remSleep],
          startPoint: .top,
          endPoint: .bottom
        )
      )
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
    .chartYScale(domain: -scheduleYMax ... -scheduleYMin)
    .chartXSelection(value: $rawScheduleSelectedDate)
    .chartOverlay { proxy in
      GeometryReader { geometry in
        if let selected = selectedSchedule,
           let xPosition = proxy.position(forX: selected.date) {
          VStack(alignment: .leading, spacing: 2) {
            Text("\(monthName(for: selected.date)) Average")
              .font(.caption2)
              .bold()
            Text("Bedtime: \(selected.bedtimeFormatted)")
            Text("Wake: \(selected.wakeTimeFormatted)")
            Text("Duration: \(formatScheduleDuration(selected.wakeTimeMinutes - selected.bedtimeMinutes))")
          }
          .font(.caption2)
          .padding(8)
          .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
          .position(x: min(max(xPosition, 50), geometry.size.width - 50), y: 0)
          .environment(\.colorScheme, .dark)
        }
      }
    }
    .frame(height: 200)
    .sensoryFeedback(.selection, trigger: selectedSchedule)
    .onChange(of: rawScheduleSelectedDate) { _, newValue in
      if let date = newValue {
        selectedSchedule = findNearestScheduleMonth(to: date)
      } else {
        selectedSchedule = nil
      }
    }
  }

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
      CoreHealth.SleepStage.core.rawValue: Color.coreSleep,
      CoreHealth.SleepStage.deep.rawValue: Color.deepSleep,
      CoreHealth.SleepStage.rem.rawValue: Color.remSleep,
      CoreHealth.SleepStage.awake.rawValue: Color.awakeSleep
    ])
    .chartXAxis(.hidden)
    .chartYAxis(.hidden)
    .chartXScale(domain: yearStart...yearEnd)
    .chartYScale(domain: 0...sleepStagesYMax)
    .chartLegend(.hidden)
    .chartXSelection(value: $rawSelectedDate)
    .chartOverlay { proxy in
      GeometryReader { geometry in
        if let selected = selectedMonth,
           let xPosition = proxy.position(forX: selected.date) {
          VStack(alignment: .leading, spacing: 2) {
            Text("\(monthName(for: selected.date)) Average")
              .font(.caption2)
              .bold()
            HStack(spacing: 4) {
              Circle().fill(Color.coreSleep).frame(width: 6, height: 6)
              Text("Core: \(selected.coreMinutesDisplay)")
            }
            HStack(spacing: 4) {
              Circle().fill(Color.deepSleep).frame(width: 6, height: 6)
              Text("Deep: \(selected.deepMinutesDisplay)")
            }
            HStack(spacing: 4) {
              Circle().fill(Color.remSleep).frame(width: 6, height: 6)
              Text("REM: \(selected.remMinutesDisplay)")
            }
            HStack(spacing: 4) {
              Circle().fill(Color.awakeSleep).frame(width: 6, height: 6)
              Text("Awake: \(selected.awakeMinutesDisplay)")
            }
          }
          .font(.caption2)
          .padding(8)
          .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
          .position(x: min(max(xPosition, 60), geometry.size.width - 60), y: -40)
          .environment(\.colorScheme, .dark)
        }
      }
    }
    .frame(height: 240)
    .sensoryFeedback(.selection, trigger: selectedMonth)
    .onChange(of: rawSelectedDate) { _, newValue in
      if let date = newValue {
        selectedMonth = findNearestMonth(to: date)
      } else {
        selectedMonth = nil
      }
    }
  }

  var scoreStatView: some View {
    HStack(spacing: 12) {
      if let lowest = stats.lowestSleepScore {
        HStack {
          Image(systemSymbol: .moonsetFill)
            .foregroundStyle(.awakeSleep)
            .font(.title2)
          VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: "\(lowest.score)")
              .font(.title2)
              .bold()
            Text("Lowest Score")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
      }

      if let highest = stats.highestSleepScore {
        HStack {
          Image(systemSymbol: .moonriseFill)
            .foregroundStyle(highest.isPerfect ? .white : .coreSleep)
            .font(.title2)
          VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: "\(highest.score)")
              .font(.title2)
              .bold()
            Text("Highest Score")
              .font(.caption)
              .foregroundStyle(highest.isPerfect ? .white.opacity(0.7) : .secondary)
          }
          .foregroundStyle(highest.isPerfect ? .white : .primary)
          Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
          highest.isPerfect
          ? AnyShapeStyle(Color.mutedGreen)
          : AnyShapeStyle(.ultraThinMaterial),
          in: RoundedRectangle(cornerRadius: 16)
        )
      }
    }
    .fontDesign(.rounded)
    .padding(.horizontal, 24)
  }
}

// MARK: - Helpers

private extension SleepStoryPage {

  var formattedSleepDuration: String {
    let totalMinutes = stats.yearTotals.averageSleepDurationMinutes
    let hours = Int(totalMinutes / 60)
    let minutes = Int(totalMinutes.truncatingRemainder(dividingBy: 60))
    return "\(hours)h \(minutes)m"
  }

  var monthlyChartData: [MonthlySleepStageChartData] {
    stats.monthlySleepStageData()
  }

  var sleepStageDataPoints: [SleepStageDataPoint] {
    stats.sleepStageDataPoints()
  }

  var sleepScheduleData: [MonthlySleepScheduleData] {
    stats.monthlySleepScheduleData()
  }

  var yearStart: Date {
    Calendar.current.date(from: DateComponents(year: stats.year, month: 1, day: 15))!
  }

  var yearEnd: Date {
    Calendar.current.date(from: DateComponents(year: stats.year, month: 12, day: 15))!
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

  var scheduleYAxisValues: [Double] {
    let interval = 240.0 // 4 hours in minutes
    let firstTick = (ceil(scheduleYMin / interval) * interval)
    let lastTick = (floor(scheduleYMax / interval) * interval)
    var values: [Double] = []
    var tick = firstTick
    while tick <= lastTick {
      values.append(-tick) // Negate for reversed Y-axis
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

  func formatCompactTime(_ minutesFromNoon: Double) -> String {
    let absMinutes = abs(minutesFromNoon)
    var minutesFromMidnight = absMinutes + 720
    if minutesFromMidnight >= 1440 {
      minutesFromMidnight -= 1440
    }
    let hours = Int(minutesFromMidnight) / 60
    let period = hours >= 12 ? "PM" : "AM"
    let displayHour = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours)
    return "\(displayHour)\(period)"
  }

  func formatScheduleDuration(_ minutes: Double) -> String {
    let hours = Int(minutes) / 60
    let mins = Int(minutes) % 60
    return "\(hours)h \(mins)m"
  }

  func monthName(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    return formatter.string(from: date)
  }

  func findNearestMonth(to date: Date) -> MonthlySleepStageChartData? {
    let calendar = Calendar.current
    let targetMonth = calendar.component(.month, from: date)
    return monthlyChartData.first { data in
      calendar.component(.month, from: data.date) == targetMonth
    }
  }

  func findNearestScheduleMonth(to date: Date) -> MonthlySleepScheduleData? {
    let calendar = Calendar.current
    let targetMonth = calendar.component(.month, from: date)
    return sleepScheduleData.first { data in
      calendar.component(.month, from: data.date) == targetMonth
    }
  }
}

#Preview {
  PreviewEnvironment {
    SleepStoryPage(stats: .preview)
  }
}
