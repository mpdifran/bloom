//
//  HeartHealthStoryPage.swift
//  Bloom
//
//  Created by Claude on 2025-12-18.
//

import SwiftUI
import Charts
import CoreHealth
import BloomUI
import SFSafeSymbols

struct HeartHealthStoryPage: View {
  let stats: YearInBloomHeartHealthStats

  @State private var rawSelectedDate: Date?
  @State private var selectedMonth: MonthlyHeartRateData?
  @State private var rawHRVSelectedDate: Date?
  @State private var selectedHRVMonth: MonthlyHRVData?

  var body: some View {
    VStack {
      heartRateChart

      heartRateStatView

      Spacer()

      Image(systemSymbol: .heartFill)
        .foregroundStyle(.mutedRed)
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

      Text("Heart Rate Variability")
        .font(.caption)
        .foregroundStyle(.secondary)
        .horizontalAlignment(.leading)
        .padding(.horizontal, 24)

      hrvChart
    }
    .ignoresSafeArea(edges: [.horizontal])
    .toolbar {
      ToolbarItem(placement: .principal) {
        titleView
      }
    }
  }

  private var focusSentence: Text {
    let baseSentence = Text("Your resting heart rate averaged ") +
      Text(formattedAverageRestingHR)
        .foregroundStyle(.mutedRed)

    guard let feedbackText = restingHeartRateFeedback else {
      return baseSentence
    }

    return baseSentence +
      Text(". ") +
      feedbackText
  }

  private var restingHeartRateFeedback: Text? {
    guard let hr = stats.yearlyAverageRestingHR else { return nil }

    let goal = HealthGoalProvider.shared.goalRestingHeartRateForUser()

    if hr <= goal.0 {
      return Text("This is ") +
        Text("excellent")
          .foregroundStyle(.mutedRed) +
        Text(" for your age!")
    } else if hr < goal.1 {
      return Text("This is ") +
        Text("great")
          .foregroundStyle(.mutedRed) +
        Text(" for your age!")
    } else {
      return Text("There's ") +
        Text("room to improve")
          .foregroundStyle(.mutedRed) +
        Text(".")
    }
  }
}

// MARK: - Title & Charts

private extension HeartHealthStoryPage {

  var titleView: some View {
    Text("Heart Health")
      .font(.title3)
      .fontDesign(.rounded)
      .bold()
  }

  var heartRateStatView: some View {
    HStack(spacing: 12) {
      HStack {
        Image(systemSymbol: .arrowDownHeartFill)
          .foregroundStyle(.white, .mutedRed)
          .font(.title2)
        VStack(alignment: .leading, spacing: 0) {
          Text("\(Int(minMinHR)) bpm")
            .font(.title2)
            .bold()
          Text("Min")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
      }
      .cardContainer(fill: .background.secondary)

      HStack {
        Image(systemSymbol: .arrowUpHeartFill)
          .foregroundStyle(.white, .mutedRed)
          .font(.title2)
        VStack(alignment: .leading, spacing: 0) {
          Text("\(Int(maxMaxHR)) bpm")
            .font(.title2)
            .bold()
          Text("Max")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
      }
      .cardContainer(fill: .background.secondary)
    }
    .fontDesign(.rounded)
    .padding(.horizontal)
  }

  var heartRateChart: some View {
    Chart {
      // Area mark showing min to max HR range
      ForEach(monthlyHeartRateWithValues) { data in
        AreaMark(
          x: .value("Month", data.date),
          yStart: .value("Min", data.averageMinHR ?? 0),
          yEnd: .value("Max", data.averageMaxHR ?? 0)
        )
        .foregroundStyle(Color.mutedRed)
        .interpolationMethod(.catmullRom)
      }
    }
    .chartXAxis(.hidden)
    .chartYAxis(.hidden)
    .chartXScale(domain: yearStart...yearEnd)
    .chartYScale(domain: 20...200)
    .chartLegend(.hidden)
    .chartXSelection(value: $rawSelectedDate)
    .frame(height: 160)
    .sensoryFeedback(.selection, trigger: selectedMonth)
    .chartOverlay { proxy in
      GeometryReader { geometry in
        if let selectedMonth, let xPosition = proxy.position(forX: selectedMonth.date) {
          heartRateOverlay(for: selectedMonth)
            .position(x: min(max(xPosition, 65), geometry.size.width - 65), y: 0)
        }
      }
    }
    .onChange(of: rawSelectedDate) { _, newValue in
      if let date = newValue {
        selectedMonth = findNearestHeartRateMonth(to: date)
      } else {
        selectedMonth = nil
      }
    }
  }

  var hrvChart: some View {
    Chart(monthlyHRVWithValues) { data in
      LineMark(
        x: .value("Month", data.date, unit: .month),
        y: .value("HRV", data.averageHRV ?? 0)
      )
      .foregroundStyle(Color.mutedRed)
      .interpolationMethod(.catmullRom)
      .lineStyle(StrokeStyle(lineWidth: 2))

      PointMark(
        x: .value("Month", data.date, unit: .month),
        y: .value("HRV", data.averageHRV ?? 0)
      )
      .symbol {
        Circle()
          .strokeBorder(Color.mutedRed, lineWidth: 2)
          .background(Circle().fill(.background))
          .frame(width: 8, height: 8)
      }
    }
    .chartXScale(domain: hrvYearStart...hrvYearEnd)
    .chartYScale(domain: minHRV...maxHRV)
    .chartXAxis {
      AxisMarks(values: .stride(by: .month)) { _ in
        AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
          .foregroundStyle(.white.opacity(0.6))
      }
    }
    .chartYAxis {
      AxisMarks { value in
        AxisGridLine()
        AxisValueLabel {
          if let hrv = value.as(Double.self) {
            Text("\(Int(hrv)) ms")
              .font(.caption2)
          }
        }
      }
    }
    .chartLegend(.hidden)
    .chartXSelection(value: $rawHRVSelectedDate)
    .frame(height: 120)
    .padding(.horizontal, 24)
    .sensoryFeedback(.selection, trigger: selectedHRVMonth)
    .chartOverlay { proxy in
      GeometryReader { geometry in
        if let selectedHRVMonth, let xPosition = proxy.position(forX: selectedHRVMonth.date) {
          hrvOverlay(for: selectedHRVMonth)
            .position(x: min(max(xPosition, 65), geometry.size.width - 65), y: 0)
        }
      }
    }
    .onChange(of: rawHRVSelectedDate) { _, newValue in
      if let date = newValue {
        selectedHRVMonth = findNearestHRVMonth(to: date)
      } else {
        selectedHRVMonth = nil
      }
    }
  }

  @ViewBuilder
  func hrvOverlay(for month: MonthlyHRVData) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("\(monthName(for: month.date)) Average")
        .font(.caption)
        .bold()

      if let hrv = month.averageHRV {
        Text("HRV: \(Int(hrv)) ms")
          .font(.caption2)
      }
    }
    .padding(8)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
  }

  @ViewBuilder
  func heartRateOverlay(for month: MonthlyHeartRateData) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("\(monthName(for: month.date)) Average")
        .font(.caption)
        .bold()

      if let maxHR = month.averageMaxHR {
        HStack(spacing: 4) {
          Circle()
            .fill(Color.mutedRed)
            .frame(width: 8, height: 8)
          Text("Max: \(Int(maxHR)) bpm")
            .font(.caption2)
        }
      }

      if let restingHR = month.averageRestingHR {
        HStack(spacing: 4) {
          Circle()
            .fill(Color.primary)
            .frame(width: 8, height: 8)
          Text("Resting: \(Int(restingHR)) bpm")
            .font(.caption2)
        }
      }

      if let minHR = month.averageMinHR {
        HStack(spacing: 4) {
          Circle()
            .fill(Color.mutedRed)
            .frame(width: 8, height: 8)
          Text("Min: \(Int(minHR)) bpm")
            .font(.caption2)
        }
      }
    }
    .padding(8)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
  }
}

// MARK: - Helpers

private extension HeartHealthStoryPage {

  var formattedAverageRestingHR: String {
    guard let hr = stats.yearlyAverageRestingHR else { return "—" }
    return "\(Int(hr)) bpm"
  }

  var yearStart: Date {
    Calendar.current.date(from: DateComponents(year: stats.year, month: 1, day: 15))!
  }

  var yearEnd: Date {
    Calendar.current.date(from: DateComponents(year: stats.year, month: 12, day: 15))!
  }

  var hrvYearStart: Date {
    Calendar.current.date(from: DateComponents(year: stats.year, month: 1, day: 1))!
  }

  var hrvYearEnd: Date {
    Calendar.current.date(from: DateComponents(year: stats.year + 1, month: 1, day: 1))!
  }

  var monthlyHeartRateWithValues: [MonthlyHeartRateData] {
    stats.monthlyHeartRateData.filter { $0.averageMinHR != nil && $0.averageMaxHR != nil }
  }

  var maxMaxHR: Double {
    stats.monthlyHeartRateData.compactMap(\.averageMaxHR).max() ?? 180
  }

  var minMinHR: Double {
    stats.monthlyHeartRateData.compactMap(\.averageMinHR).min() ?? 45
  }

  var monthlyHRVWithValues: [MonthlyHRVData] {
    stats.monthlyHRVData.filter { $0.averageHRV != nil }
  }

  var minHRV: Double {
    let values = monthlyHRVWithValues.compactMap(\.averageHRV)
    return (values.min() ?? 20) - 5
  }

  var maxHRV: Double {
    let values = monthlyHRVWithValues.compactMap(\.averageHRV)
    return (values.max() ?? 80) + 5
  }

  func findNearestHeartRateMonth(to date: Date) -> MonthlyHeartRateData? {
    let calendar = Calendar.current
    let targetMonth = calendar.component(.month, from: date)
    return stats.monthlyHeartRateData.first { data in
      calendar.component(.month, from: data.date) == targetMonth
    }
  }

  func findNearestHRVMonth(to date: Date) -> MonthlyHRVData? {
    let calendar = Calendar.current
    let targetMonth = calendar.component(.month, from: date)
    return stats.monthlyHRVData.first { data in
      calendar.component(.month, from: data.date) == targetMonth
    }
  }

  func monthName(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM"
    return formatter.string(from: date)
  }
}

#Preview {
  PreviewEnvironment {
    HeartHealthStoryPage(stats: .preview)
  }
}
