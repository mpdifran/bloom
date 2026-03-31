//
//  BedtimeSleepDurationDetailsView.swift
//  Bloom
//
//  Created by Assistant on 2026-01-09.
//

import SwiftUI
import Charts
import TelemetryDeck
import SFSafeSymbols

struct BedtimeSleepDurationDetailsView: View {
  @State private var selectedPeriod: StatTimePeriod = .sevenDays
  @State private var summaryData: BedtimeSleepDurationSummary?
  @State private var rawSelectedDate: Date?
  @State private var selectedDataPoint: BedtimeSleepDurationDataPoint?

  var body: some View {
    Group {
      if summaryData?.hasNoData == false {
        contentView
      } else {
        emptyView
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Bedtime & Duration",
          subtitle: selectedPeriod.displayName
        )
      }
    }
    .navigationTitle("Bedtime & Duration")
    .navigationBarTitleDisplayMode(.inline)
    .animation(.default, value: summaryData?.dataPoints.map(\.id))
    .task(id: selectedPeriod) {
      summaryData = await YouStatsCalculator.shared.calculateBedtimeSleepDurationForPeriod(selectedPeriod)
    }
    .onAppear {
      TelemetryDeck.viewScreen("Bedtime Duration Details")
    }
  }
}

// MARK: - Content Views

private extension BedtimeSleepDurationDetailsView {

  var contentView: some View {
    BloomScrollView(spacing: 20) {
      StatTimePeriodPicker(selectedPeriod: $selectedPeriod)

      sleepScheduleChart
      consistencySection
      trendSection
    }
  }

  var emptyView: some View {
    ContentUnavailableView(
      "No Sleep Data",
      systemImage: "bed.double.fill",
      description: Text("Enable Sleep Focus and wear your Apple Watch to bed to track your sleep schedule.")
    )
  }
}

// MARK: - Sleep Schedule Chart

private extension BedtimeSleepDurationDetailsView {

  var sleepScheduleChart: some View {
    VStack(alignment: .leading) {
      VStack {
        VitalDetailChartTitleView(
          title: "Sleep Schedule",
          value: summaryData?.averageDurationFormatted ?? ""
        )

        Chart(summaryData?.dataPoints ?? []) { data in
          BarMark(
            x: .value("Date", data.date, unit: chartUnit),
            yStart: .value("Bedtime", -data.bedtimeMinutesFromNoon),
            yEnd: .value("Wake", -data.wakeTimeMinutesFromNoon)
          )
          .foregroundStyle(
            LinearGradient(
              colors: [.deepSleep, .coreSleep],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .cornerRadius(4)

          if let selected = selectedDataPoint, selected.date == data.date {
            RuleMark(x: .value("Selected", data.date, unit: chartUnit))
              .foregroundStyle(.secondary.opacity(0.5))
              .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
          }
        }
        .chartXAxis {
          AxisMarks(values: .automatic) { _ in
            AxisGridLine()
            AxisValueLabel(format: selectedPeriod.chartDateFormat)
          }
        }
        .chartYAxis {
          AxisMarks(values: yAxisValues) { value in
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
        .chartXScale(domain: xDomain)
        .chartYScale(domain: -yMax ... -yMin)
        .chartXSelection(value: $rawSelectedDate)
        .chartOverlay { proxy in
          selectionOverlay(proxy: proxy)
        }
        .frame(height: 200)
      }
      .cardContainer()

      DetailInfoCardView {
        Text("This chart shows your sleep schedule over time. Each bar represents a night of sleep, starting at your bedtime and ending at your wake time. A consistent sleep schedule helps regulate your circadian rhythm and improves sleep quality.")
      }
    }
    .sensoryFeedback(.selection, trigger: selectedDataPoint?.id)
    .onChange(of: rawSelectedDate) { _, newValue in
      selectedDataPoint = findNearestDataPoint(to: newValue)
    }
  }

  @ViewBuilder
  func selectionOverlay(proxy: ChartProxy) -> some View {
    GeometryReader { geometry in
      if let selected = selectedDataPoint,
         let xPosition = proxy.position(forX: selected.date) {
        VStack(alignment: .leading, spacing: 4) {
          Text(formatDate(selected.date))
            .font(.caption2)
            .bold()
          HStack(spacing: 4) {
            Circle().fill(Color.deepSleep).frame(width: 6, height: 6)
            Text("Bedtime: \(formatTimeFromNoon(selected.bedtimeMinutesFromNoon))")
          }
          HStack(spacing: 4) {
            Circle().fill(Color.coreSleep).frame(width: 6, height: 6)
            Text("Wake: \(formatTimeFromNoon(selected.wakeTimeMinutesFromNoon))")
          }
          Text("Duration: \(formatDuration(selected.durationMinutes))")
        }
        .font(.caption2)
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .position(x: min(max(xPosition, 70), geometry.size.width - 70), y: 50)
      }
    }
  }
}

// MARK: - Summary Sections

private extension BedtimeSleepDurationDetailsView {

  func averageStatCard(title: String, value: String, color: Color) -> some View {
    HStack(spacing: 4) {
      Capsule()
        .fill(color)
        .frame(width: 6, height: 20)
        .fixedSize()

      Text(title)
        .font(.body)
        .bold()

      Spacer()

      Text(value)
        .font(.body)
        .bold()
        .fontDesign(.rounded)
    }
    .padding(12)
    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
  }

  var consistencySection: some View {
    VStack(alignment: .leading, spacing: 12) {
      VitalDetailChartTitleView(title: "Consistency", value: "")

      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Bedtime")
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(summaryData?.consistencyDescription ?? "--")
            .font(.subheadline)
            .bold()
            .fontDesign(.rounded)
          if let stdDev = summaryData?.bedtimeStandardDeviationMinutes {
            Text("\u{00B1}\(Int(stdDev)) min variation")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))

        VStack(alignment: .leading, spacing: 4) {
          Text("Wake Time")
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(summaryData?.wakeTimeConsistencyDescription ?? "--")
            .font(.subheadline)
            .bold()
            .fontDesign(.rounded)
          if let stdDev = summaryData?.wakeTimeStandardDeviationMinutes {
            Text("\u{00B1}\(Int(stdDev)) min variation")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
      }

      averageStatCard(
        title: "Bedtime",
        value: summaryData?.averageBedtimeFormatted ?? "--",
        color: .deepSleep
      )

      averageStatCard(
        title: "Wake Time",
        value: summaryData?.averageWakeTimeFormatted ?? "--",
        color: .coreSleep
      )

    }
    .cardContainer()
  }

  @ViewBuilder
  var trendSection: some View {
    if let change = summaryData?.durationChangeFromPreviousPeriod {
      VStack(alignment: .leading, spacing: 12) {

        VitalDetailChartTitleView(
          title: "Duration Trends",
          valueLabel: selectedPeriod.comparisonPeriodLabel,
          value: formatPercentChange(change)
        )

        HStack {
          VStack(spacing: 4) {
            Text(summaryData?.previousPeriodAverageDurationFormatted ?? "--")
              .font(.largeTitle)
              .bold()
              .fontDesign(.rounded)
            Text(selectedPeriod.previousPeriodLabel)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity)

          Image(systemSymbol: .arrowRight)
            .font(.title2)
            .foregroundStyle(.secondary)

          VStack(spacing: 4) {
            Text(summaryData?.averageDurationFormatted ?? "--")
              .font(.largeTitle)
              .bold()
              .fontDesign(.rounded)
            Text(selectedPeriod.currentPeriodLabel)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity)
        }

        Divider()

        HStack {
          Image(systemSymbol: change >= 0 ? .arrowUpCircleFill : .arrowDownCircle)
            .foregroundStyle(arrowForeground(for: change), arrowForeground(for: change).tertiary)
            .font(.title3)
            .bold()
            .fontDesign(.rounded)

          Text(trendDescription(for: change))
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }
      .cardContainer()
    }
  }

  func arrowForeground(for change: Double) -> Color {
    change >= 0 ? .mutedGreen : .mutedOrange
  }
}

// MARK: - Helpers

private extension BedtimeSleepDurationDetailsView {

  var chartUnit: Calendar.Component {
    selectedPeriod.aggregatesByWeek ? .weekOfYear : .day
  }

  var yMin: Double {
    guard let data = summaryData?.dataPoints, data.isNotEmpty else { return 600 }
    let minBedtime = data.map(\.bedtimeMinutesFromNoon).min() ?? 600
    return minBedtime - 60
  }

  var yMax: Double {
    guard let data = summaryData?.dataPoints, data.isNotEmpty else { return 1200 }
    let maxWakeTime = data.map(\.wakeTimeMinutesFromNoon).max() ?? 1200
    return maxWakeTime + 60
  }

  var xDomain: ClosedRange<Date> {
    let dateRange = selectedPeriod.dateRange
    return dateRange.start...dateRange.end
  }

  var yAxisValues: [Double] {
    let interval = 120.0 // 2 hours
    let firstTick = (ceil(yMin / interval) * interval)
    let lastTick = (floor(yMax / interval) * interval)
    var values: [Double] = []
    var tick = firstTick
    while tick <= lastTick {
      values.append(-tick)
      tick += interval
    }
    return values
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

  func formatTimeFromNoon(_ minutesFromNoon: Double) -> String {
    var minutesFromMidnight = minutesFromNoon + 720
    if minutesFromMidnight >= 1440 {
      minutesFromMidnight -= 1440
    }
    let hours = Int(minutesFromMidnight) / 60
    let minutes = Int(minutesFromMidnight) % 60
    let period = hours >= 12 ? "PM" : "AM"
    let displayHour = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours)
    return String(format: "%d:%02d %@", displayHour, minutes, period)
  }

  func formatDuration(_ minutes: Double) -> String {
    let hours = Int(minutes) / 60
    let mins = Int(minutes) % 60
    return "\(hours)h \(mins)m"
  }

  func formatDate(_ date: Date) -> String {
    if selectedPeriod.aggregatesByWeek {
      return date.formatted(.dateTime.month(.abbreviated).day())
    }
    return date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
  }

  func formatPercentChange(_ change: Double) -> String {
    let sign = change >= 0 ? "+" : ""
    return "\(sign)\(Int(change))%"
  }

  func trendDescription(for change: Double) -> String {
    if abs(change) < 5 {
      return "Your sleep duration is about the same as before."
    } else if change > 0 {
      return "You're sleeping more than the previous period."
    } else {
      return "You're sleeping less than the previous period."
    }
  }

  func trendSymbol(for trend: BedtimeTrend) -> SFSymbol {
    switch trend {
    case .trendingEarlier: return .arrowUpCircleFill
    case .trendingLater: return .arrowDownCircleFill
    case .inconsistent: return .arrowLeftArrowRightCircleFill
    case .consistent: return .checkmark
    }
  }

  func trendColor(for trend: BedtimeTrend) -> Color {
    switch trend {
    case .trendingEarlier: return .mutedGreen
    case .trendingLater: return .mutedOrange
    case .inconsistent: return .mutedYellow
    case .consistent: return .mutedGreen
    }
  }

  func findNearestDataPoint(to date: Date?) -> BedtimeSleepDurationDataPoint? {
    guard let date, let data = summaryData?.dataPoints, data.isNotEmpty else { return nil }
    let calendar = Calendar.current

    if selectedPeriod.aggregatesByWeek {
      return data.first { dataPoint in
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: dataPoint.date) else { return false }
        return weekInterval.contains(date)
      }
    } else {
      return data.first { dataPoint in
        calendar.isDate(dataPoint.date, inSameDayAs: date)
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      BedtimeSleepDurationDetailsView()
    }
  }
}
