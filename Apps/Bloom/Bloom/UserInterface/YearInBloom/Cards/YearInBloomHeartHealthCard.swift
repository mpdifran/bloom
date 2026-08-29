//
//  YearInBloomHeartHealthCard.swift
//  Bloom
//
//  Created by Claude on 2025-12-17.
//

import SwiftUI
import Charts
import CoreHealth
import BloomUI
import SFSafeSymbols

struct YearInBloomHeartHealthCard: View {
  let stats: YearInBloomHeartHealthStats

  @State private var rawSelectedDate: Date?
  @State private var selectedMonth: MonthlyHeartRateData?
  @State private var rawHRVSelectedDate: Date?
  @State private var selectedHRVMonth: MonthlyHRVData?

  var body: some View {
    YearInBloomCard(
      title: String(localized: "Heart Health", comment: "Year in Bloom card title"),
      focusStat: formattedAverageRestingHR,
      focusStatLabel: "Avg Resting HR",
      includePadding: false,
      includeDivider: false,
      foregroundFill: .white,
      backgroundFill: .black
    ) {
      VStack {
        heartRateChart

        Text("Heart Rate Variability")
          .font(.caption2)
          .foregroundStyle(.secondary)
          .horizontalAlignment(.leading)
          .padding(.horizontal)
          .padding(.top)
        hrvChart
          .padding(.bottom)
      }
    }
    .environment(\.colorScheme, .dark)
  }
}

// MARK: - Charts

private extension YearInBloomHeartHealthCard {

  var heartRateChart: some View {
    Chart(heartRateDataPoints) { dataPoint in
      AreaMark(
        x: .value("Month", dataPoint.date),
        y: .value("HR", dataPoint.heartRate),
        stacking: .standard
      )
      .foregroundStyle(by: .value("Type", dataPoint.type))
      .interpolationMethod(.catmullRom)
    }
    .chartForegroundStyleScale([
      "Resting": Color.clear,
      "Range": Color.mutedRed
    ])
    .chartXAxis(.hidden)
    .chartYAxis(.hidden)
    .chartXScale(domain: yearStart...yearEnd)
    .chartYScale(domain: (minRestingHR - 5)...(maxMaxHR + 5))
    .chartLegend(.hidden)
    .chartXSelection(value: $rawSelectedDate)
    .frame(height: 180)
    .sensoryFeedback(.selection, trigger: selectedMonth)
    .overlay(alignment: .topTrailing) {
      Text("MAX: \(Int(maxMaxHR))")
        .font(.caption2)
        .bold()
        .foregroundStyle(.white)
        .padding(.trailing, 4)
        .padding(.top, 4)
    }
    .overlay(alignment: .bottomTrailing) {
      Text("RHR: \(Int(minRestingHR))")
        .font(.caption2)
        .bold()
        .foregroundStyle(.white)
        .padding(.trailing, 4)
        .padding(.bottom, 4)
    }
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
          .background(Circle().fill(.black))
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
      AxisMarks {
        AxisGridLine()
      }
    }
    .chartLegend(.hidden)
    .chartXSelection(value: $rawHRVSelectedDate)
    .frame(height: 140)
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
            .fill(Color.mutedRed)
            .frame(width: 8, height: 8)
          Text("Resting: \(Int(restingHR)) bpm")
            .font(.caption2)
        }
      }
    }
    .padding(8)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
  }
}

// MARK: - Computed Properties

private extension YearInBloomHeartHealthCard {

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

  var heartRateDataPoints: [HeartRateDataPoint] {
    var dataPoints = [HeartRateDataPoint]()

    for monthData in stats.monthlyHeartRateData {
      guard let restingHR = monthData.averageRestingHR,
            let maxHR = monthData.averageMaxHR else { continue }

      // Bottom layer: Resting HR
      dataPoints.append(HeartRateDataPoint(
        date: monthData.date,
        type: "Resting",
        heartRate: restingHR
      ))

      // Top layer: Range (max - resting)
      dataPoints.append(HeartRateDataPoint(
        date: monthData.date,
        type: "Range",
        heartRate: maxHR - restingHR
      ))
    }

    return dataPoints
  }

  var maxMaxHR: Double {
    stats.monthlyHeartRateData.compactMap(\.averageMaxHR).max() ?? 180
  }

  var minRestingHR: Double {
    stats.monthlyHeartRateData.compactMap(\.averageRestingHR).min() ?? 50
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
    // Locale-aware month name; a fixed "MMMM" pattern rendered English months in every language.
    date.formatted(.dateTime.month(.wide))
  }
}

// MARK: - Heart Rate Data Point

struct HeartRateDataPoint: Identifiable {
  var id: String { "\(date.timeIntervalSince1970)-\(type)" }
  let date: Date
  let type: String
  let heartRate: Double
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      YearInBloomHeartHealthCard(stats: .preview)
    }
  }
}
