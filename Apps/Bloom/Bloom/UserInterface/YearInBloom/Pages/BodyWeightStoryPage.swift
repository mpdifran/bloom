//
//  BodyWeightStoryPage.swift
//  Bloom
//
//  Created by Claude on 2025-12-18.
//

import SwiftUI
import Charts
import CoreHealth
import BloomUI
import SFSafeSymbols
import HealthKit

struct BodyWeightStoryPage: View {
  let stats: YearInBloomBodyWeightStats

  @State private var rawSelectedDate: Date?
  @State private var selectedMonth: MonthlyWeightData?

  var body: some View {
    VStack {
      weightChart
        .padding(.top)

      Spacer()

      Image(systemSymbol: .scalemassFill)
        .foregroundStyle(.tint)
        .font(.system(size: 50))
        .padding(.bottom)

      focusSection
        .fixedSize(horizontal: false, vertical: true)

      Spacer()

      statsGrid
    }
    .padding(.vertical)
    .tint(.mutedIndigo)
    .toolbar {
      ToolbarItem(placement: .principal) {
        titleView
      }
    }
  }

  private var focusSentence: Text {
    if let change = weightChange {
      let amount = Text(formattedWeightChange).foregroundStyle(.tint)

      if change < 0 {
        return Text(
          "You lost \(amount) this year.",
          comment: "Year in Bloom weight summary. The placeholder is an amount of weight lost."
        )
      } else if change > 0 {
        return Text(
          "You gained \(amount) this year.",
          comment: "Year in Bloom weight summary. The placeholder is an amount of weight gained."
        )
      }
    }
    return Text("Your weight stayed stable this year.")
  }

  private var focusSection: some View {
    focusSentence
      .font(.title)
      .fontWeight(.bold)
      .fontDesign(.rounded)
      .multilineTextAlignment(.center)
  }
}

// MARK: - Title & Chart

private extension BodyWeightStoryPage {

  var titleView: some View {
    Text("Body Weight")
      .font(.title3)
      .fontDesign(.rounded)
      .bold()
  }

  var weightChart: some View {
    Chart(monthlyWeightWithValues) { data in
      AreaMark(
        x: .value("Month", data.date),
        y: .value("Weight", data.averageWeight ?? 0)
      )
      .foregroundStyle(.tint.opacity(0.5))
      .interpolationMethod(.catmullRom)

      LineMark(
        x: .value("Month", data.date),
        y: .value("Weight", data.averageWeight ?? 0)
      )
      .foregroundStyle(.tint)
      .interpolationMethod(.catmullRom)
    }
    .chartXAxis(.hidden)
    .chartYAxis(.hidden)
    .chartXScale(domain: yearStart...yearEnd)
    .chartYScale(domain: (minWeightValue - weightPadding)...(maxWeightValue + weightPadding))
    .chartLegend(.hidden)
    .frame(height: 200)
  }

  @ViewBuilder
  func weightOverlay(for month: MonthlyWeightData) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("\(monthName(for: month.date)) Average")
        .font(.caption)
        .bold()

      if let weight = month.averageWeight {
        Text(formattedWeight(weight))
          .font(.caption2)
      }
    }
    .padding(8)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
  }
}

// MARK: - Stats Grid

private extension BodyWeightStoryPage {

  @ViewBuilder
  var statsGrid: some View {
    if let minFat = minBodyFat, let maxFat = maxBodyFat {
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        minBodyFatCard(minFat)
        maxBodyFatCard(maxFat)
      }
      .padding(.horizontal)
    }
  }

  func minBodyFatCard(_ value: Double) -> some View {
    HStack {
      Image(systemSymbol: .arrowDown)
        .foregroundStyle(.tint)
        .font(.title2)
      VStack(alignment: .leading, spacing: 0) {
        Text(formatBodyFat(value))
          .font(.title3)
          .bold()
        Text("Lowest Body Fat %")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
    }
    .cardContainer(fill: .background.secondary)
  }

  func maxBodyFatCard(_ value: Double) -> some View {
    HStack {
      Image(systemSymbol: .arrowUp)
        .foregroundStyle(.tint)
        .font(.title2)
      VStack(alignment: .leading, spacing: 0) {
        Text(formatBodyFat(value))
          .font(.title3)
          .bold()
        Text("Highest Body Fat %")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
    }
    .cardContainer(fill: .background.secondary)
  }
}

// MARK: - Helpers

private extension BodyWeightStoryPage {

  var weightChange: Double? {
    guard let start = stats.yearStartWeight, let end = stats.yearEndWeight else { return nil }
    return end - start
  }

  var formattedWeightChange: String {
    guard let change = weightChange else { return "—" }
    return formattedWeight(abs(change))
  }

  func formattedWeight(_ pounds: Double) -> String {
    HKQuantity(unit: .pound(), doubleValue: pounds)
      .displayString(for: .pound())
  }

  var minBodyFat: Double? {
    stats.monthlyBodyFatData.compactMap(\.averageBodyFat).min()
  }

  var maxBodyFat: Double? {
    stats.monthlyBodyFatData.compactMap(\.averageBodyFat).max()
  }

  func formatBodyFat(_ value: Double) -> String {
    "\(Int(value * 100))%"
  }

  var yearStart: Date {
    Calendar.current.date(from: DateComponents(year: stats.year, month: 1, day: 15))!
  }

  var yearEnd: Date {
    Calendar.current.date(from: DateComponents(year: stats.year, month: 12, day: 15))!
  }

  var monthlyWeightWithValues: [MonthlyWeightData] {
    var data = stats.monthlyWeightData.filter { $0.averageWeight != nil }

    // If December doesn't have data, add a data point using the latest available weight
    let calendar = Calendar.current
    let hasDecemberData = data.contains { calendar.component(.month, from: $0.date) == 12 }

    if !hasDecemberData, let lastWeight = data.last?.averageWeight {
      let decemberDate = calendar.date(from: DateComponents(year: stats.year, month: 12, day: 15))!
      data.append(MonthlyWeightData(
        date: decemberDate,
        minWeight: lastWeight,
        maxWeight: lastWeight,
        averageWeight: lastWeight
      ))
    }

    return data
  }

  var maxWeightValue: Double {
    stats.monthlyWeightData.compactMap(\.averageWeight).max() ?? 175
  }

  var minWeightValue: Double {
    stats.monthlyWeightData.compactMap(\.averageWeight).min() ?? 130
  }

  var weightPadding: Double {
    5
  }

  func findNearestWeightMonth(to date: Date) -> MonthlyWeightData? {
    let calendar = Calendar.current
    let targetMonth = calendar.component(.month, from: date)
    return stats.monthlyWeightData.first { data in
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
    BodyWeightStoryPage(stats: .preview)
  }
}
