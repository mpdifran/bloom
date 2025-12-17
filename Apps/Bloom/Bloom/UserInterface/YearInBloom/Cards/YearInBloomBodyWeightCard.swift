//
//  YearInBloomBodyWeightCard.swift
//  Bloom
//
//  Created by Claude on 2025-12-17.
//

import SwiftUI
import Charts
import CoreHealth
import BloomUI
import HealthKit

struct YearInBloomBodyWeightCard: View {
  let stats: YearInBloomBodyWeightStats

  @State private var rawSelectedDate: Date?
  @State private var selectedMonth: MonthlyWeightData?

  var body: some View {
    YearInBloomCard(
      title: "Body Weight",
      focusStat: formattedWeightChange,
      focusStatLabel: weightChangeLabel,
      includePadding: false,
      includeDivider: false,
      foregroundFill: .white,
      backgroundFill: .mutedIndigo.gradient
    ) {
      weightChart
    }
    .environment(\.colorScheme, .dark)
  }
}

// MARK: - Chart

private extension YearInBloomBodyWeightCard {

  var weightChart: some View {
    Chart(monthlyWeightWithValues) { data in
      AreaMark(
        x: .value("Month", data.date),
        y: .value("Weight", data.averageWeight ?? 0)
      )
      .foregroundStyle(Color.white.opacity(0.5))
      .interpolationMethod(.catmullRom)
    }
    .chartXAxis(.hidden)
    .chartYAxis(.hidden)
    .chartXScale(domain: yearStart...yearEnd)
    .chartYScale(domain: (minWeightValue - weightPadding)...(maxWeightValue + weightPadding))
    .chartLegend(.hidden)
    .chartXSelection(value: $rawSelectedDate)
    .frame(height: 200)
    .sensoryFeedback(.selection, trigger: selectedMonth)
    .overlay(alignment: .topTrailing) {
      Text("MAX: \(formattedWeight(maxWeightValue))")
        .font(.caption2)
        .bold()
        .foregroundStyle(.white)
        .padding(.trailing, 4)
        .padding(.top, 4)
    }
    .overlay(alignment: .bottomTrailing) {
      Text("MIN: \(formattedWeight(minWeightValue))")
        .font(.caption2)
        .bold()
        .foregroundStyle(.white)
        .padding(.trailing, 4)
        .padding(.bottom, 16)
    }
    .chartOverlay { proxy in
      GeometryReader { geometry in
        if let selectedMonth, let xPosition = proxy.position(forX: selectedMonth.date) {
          weightOverlay(for: selectedMonth)
            .position(x: min(max(xPosition, 65), geometry.size.width - 65), y: 0)
        }
      }
    }
    .onChange(of: rawSelectedDate) { _, newValue in
      if let date = newValue {
        selectedMonth = findNearestWeightMonth(to: date)
      } else {
        selectedMonth = nil
      }
    }
  }

  @ViewBuilder
  func weightOverlay(for month: MonthlyWeightData) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("\(monthName(for: month.date)) Average")
        .font(.caption)
        .bold()

      if let weight = month.averageWeight {
        Text("\(formattedWeight(weight)) \(unitString)")
          .font(.caption2)
      }
    }
    .padding(8)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
  }
}

// MARK: - Computed Properties

private extension YearInBloomBodyWeightCard {

  var preferredUnit: HKUnit {
    HealthUnitPreferences.shared.weightUnit
  }

  var unitString: String {
    preferredUnit == .pound() ? "lbs" : "kg"
  }

  var formattedWeightChange: String {
    guard let startWeight = stats.yearStartWeight,
          let endWeight = stats.yearEndWeight else { return "—" }

    let changeInGrams = endWeight - startWeight
    let quantity = HKQuantity(unit: .gram(), doubleValue: abs(changeInGrams))
    let valueInPreferredUnit = quantity.doubleValue(for: preferredUnit)

    if changeInGrams < 0 {
      return String(format: "-%.1f %@", valueInPreferredUnit, unitString)
    } else if changeInGrams > 0 {
      return String(format: "+%.1f %@", valueInPreferredUnit, unitString)
    } else {
      return "0 \(unitString)"
    }
  }

  var weightChangeLabel: String {
    "Weight Change"
  }

  func formattedWeight(_ grams: Double) -> String {
    let quantity = HKQuantity(unit: .gram(), doubleValue: grams)
    let value = quantity.doubleValue(for: preferredUnit)
    return String(format: "%.0f", value)
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
    stats.monthlyWeightData.compactMap(\.averageWeight).max() ?? 80_000
  }

  var minWeightValue: Double {
    stats.monthlyWeightData.compactMap(\.averageWeight).min() ?? 60_000
  }

  var weightPadding: Double {
    2_000
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

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      YearInBloomBodyWeightCard(stats: .preview)
    }
  }
}
