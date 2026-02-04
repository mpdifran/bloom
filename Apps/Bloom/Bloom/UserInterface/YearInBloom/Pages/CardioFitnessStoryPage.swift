//
//  CardioFitnessStoryPage.swift
//  Bloom
//
//  Created by Claude on 2025-12-18.
//

import SwiftUI
import Charts
import CoreHealth
import BloomUI
import SFSafeSymbols

// MARK: - VO2 Max Trend

enum VO2MaxTrend {
  case improving
  case stable
  case declining

  var symbol: SFSymbol {
    switch self {
    case .improving: .chevronUpCircleFill
    case .stable: .minusCircleFill
    case .declining: .chevronDownCircleFill
    }
  }

  var label: String {
    switch self {
    case .improving: "Improving"
    case .stable: "Stable"
    case .declining: "Declining"
    }
  }
}

struct CardioFitnessStoryPage: View {
  let stats: YearInBloomWorkoutStats

  var body: some View {
    VStack {
      vo2MaxChart

      Spacer()

      Image(systemSymbol: .boltHeartFill)
        .foregroundStyle(.white, yearlyAverageColor)
        .font(.system(size: 50))
        .contentTransition(.symbolEffect)
        .padding(.bottom)

      focusSentence
        .font(.title)
        .fontWeight(.bold)
        .fontDesign(.rounded)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
        .fixedSize(horizontal: false, vertical: true)

      Spacer()

      statCardsView
    }
    .ignoresSafeArea(edges: [.horizontal])
    .tint(yearlyAverageColor)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text("Cardio Fitness")
          .font(.title3)
          .fontDesign(.rounded)
          .bold()
      }
    }
  }

  private var focusSentence: Text {
    if let level = stats.currentCardioFitnessLevel {
      return Text("Your cardio fitness is ") +
        Text(level.name)
          .foregroundStyle(level.color) +
        Text(formattedVO2Max) +
      Text(" mL/kg/min.")
    }
    return Text("Track more cardio workouts to see your fitness level.")
      .foregroundStyle(.secondary)
  }
}

// MARK: - Chart

private extension CardioFitnessStoryPage {

  var vo2MaxChart: some View {
    Chart {
      // Threshold indicators (only show if within visible range)
      if let thresholds = vo2MaxThresholds {
        if thresholds.2 >= minVO2Max && thresholds.2 <= maxVO2Max {
          RuleMark(y: .value(HeartHealthMonthlySummary.CardioFitnessLevel.belowAverage.name, thresholds.2))
            .foregroundStyle(HeartHealthMonthlySummary.CardioFitnessLevel.belowAverage.color)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .annotation(position: .top, alignment: .leading) {
              Text(HeartHealthMonthlySummary.CardioFitnessLevel.belowAverage.name)
                .font(.caption2)
                .foregroundStyle(HeartHealthMonthlySummary.CardioFitnessLevel.belowAverage.color)
            }
        }

        if thresholds.1 >= minVO2Max && thresholds.1 <= maxVO2Max {
          RuleMark(y: .value(HeartHealthMonthlySummary.CardioFitnessLevel.aboveAverage.name, thresholds.1))
            .foregroundStyle(HeartHealthMonthlySummary.CardioFitnessLevel.aboveAverage.color)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .annotation(position: .top, alignment: .leading) {
              Text(HeartHealthMonthlySummary.CardioFitnessLevel.aboveAverage.name)
                .font(.caption2)
                .foregroundStyle(HeartHealthMonthlySummary.CardioFitnessLevel.aboveAverage.color)
            }
        }

        if thresholds.0 >= minVO2Max && thresholds.0 <= maxVO2Max {
          RuleMark(y: .value(HeartHealthMonthlySummary.CardioFitnessLevel.high.name, thresholds.0))
            .foregroundStyle(HeartHealthMonthlySummary.CardioFitnessLevel.high.color)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .annotation(position: .top, alignment: .leading) {
              Text(HeartHealthMonthlySummary.CardioFitnessLevel.high.name)
                .font(.caption2)
                .foregroundStyle(HeartHealthMonthlySummary.CardioFitnessLevel.high.color)
            }
        }
      }

      ForEach(monthlyDataWithValues) { data in
        LineMark(
          x: .value("Month", data.date, unit: .month),
          y: .value("VO₂ Max", data.averageVO2Max ?? 0)
        )
        .foregroundStyle(yearlyAverageColor)
        .interpolationMethod(.catmullRom)
        .lineStyle(StrokeStyle(lineWidth: 2))

        PointMark(
          x: .value("Month", data.date, unit: .month),
          y: .value("VO₂ Max", data.averageVO2Max ?? 0)
        )
        .symbol {
          Circle()
            .strokeBorder(yearlyAverageColor, lineWidth: 2)
            .background(Circle().fill(.background))
            .frame(width: 8, height: 8)
        }
      }
    }
    .chartXAxis(.hidden)
    .chartYAxis(.hidden)
    .chartYScale(domain: minVO2Max...maxVO2Max)
    .chartXScale(domain: yearStart...yearEnd)
    .chartLegend(.hidden)
    .frame(height: 240)
  }
}

// MARK: - Stat Cards

private extension CardioFitnessStoryPage {

  var statCardsView: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
      // Current VO2 Max
      if let vo2Max = stats.latestVO2Max {
        HStack {
          Image(systemSymbol: .heartFill)
            .foregroundStyle(yearlyAverageColor)
            .font(.title2)
          VStack(alignment: .leading, spacing: 0) {
            Text(String(format: "%.1f", vo2Max))
              .font(.title2)
              .bold()
            Text("Current VO₂ Max")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Spacer()
        }
        .cardContainer(fill: .background.secondary)
      }

      // Year Change
      if let change = vo2MaxChange {
        HStack {
          Image(systemSymbol: change >= 0 ? .arrowUpCircleFill : .arrowDownCircleFill)
            .foregroundStyle(.white, change >= 0 ? Color.vitalGood : Color.vitalWarning)
            .font(.title2)
          VStack(alignment: .leading, spacing: 0) {
            Text(change >= 0 ? "+\(String(format: "%.1f", change))" : String(format: "%.1f", change))
              .font(.title2)
              .bold()
            Text("Year Change")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Spacer()
        }
        .cardContainer(fill: .background.secondary)
      }

      // Peak VO2 Max
      if let peakVO2Max = peakVO2Max {
        HStack {
          Image(systemSymbol: .arrowUpHeartFill)
            .foregroundStyle(.white, yearlyAverageColor)
            .font(.title2)
          VStack(alignment: .leading, spacing: 0) {
            Text(String(format: "%.1f", peakVO2Max))
              .font(.title2)
              .bold()
            Text("Peak VO₂ Max")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Spacer()
        }
        .cardContainer(fill: .background.secondary)
      }

      // Trend
      if let trend = vo2MaxTrend {
        HStack {
          Image(systemSymbol: trend.symbol)
            .foregroundStyle(.white, yearlyAverageColor)
            .font(.title2)
          VStack(alignment: .leading, spacing: 0) {
            Text(trend.label)
              .font(.title2)
              .bold()
            Text("VO₂ Max Trend")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Spacer()
        }
        .cardContainer(fill: .background.secondary)
      }
    }
    .fontDesign(.rounded)
    .padding(.horizontal)
  }
}

// MARK: - Helpers

private extension CardioFitnessStoryPage {

  var formattedVO2Max: String {
    guard let vo2Max = stats.latestVO2Max else { return "" }
    return " at \(String(format: "%.1f", vo2Max))"
  }

  var vo2MaxChange: Double? {
    let values = stats.monthlyVO2Max.compactMap(\.averageVO2Max)
    guard let first = values.first, let last = values.last else { return nil }
    return last - first
  }

  var peakVO2Max: Double? {
    stats.monthlyVO2Max.compactMap(\.averageVO2Max).max()
  }

  var monthlyDataWithValues: [MonthlyVO2MaxData] {
    stats.monthlyVO2Max.filter { $0.averageVO2Max != nil }
  }

  var minVO2Max: Double {
    let values = monthlyDataWithValues.compactMap(\.averageVO2Max)
    return (values.min() ?? 0) - 2
  }

  var maxVO2Max: Double {
    let values = monthlyDataWithValues.compactMap(\.averageVO2Max)
    return (values.max() ?? 50) + 2
  }

  var yearStart: Date {
    Calendar.current.date(from: DateComponents(year: stats.year, month: 1, day: 1))!
  }

  var yearEnd: Date {
    Calendar.current.date(from: DateComponents(year: stats.year, month: 12, day: 31))!
  }

  var vo2MaxThresholds: (Double, Double, Double)? {
    HealthGoalProvider.shared.goalVO2MaxForUser()
  }

  var yearlyAverageColor: Color {
    let values = monthlyDataWithValues.compactMap(\.averageVO2Max)
    guard !values.isEmpty else { return .primary }
    let average = values.reduce(0, +) / Double(values.count)

    guard let thresholds = vo2MaxThresholds else { return .primary }
    let level: HeartHealthMonthlySummary.CardioFitnessLevel
    if average < thresholds.2 { level = .low }
    else if average < thresholds.1 { level = .belowAverage }
    else if average < thresholds.0 { level = .aboveAverage }
    else { level = .high }

    return level.color
  }

  var vo2MaxTrend: VO2MaxTrend? {
    let sortedData = monthlyDataWithValues.sorted { $0.date < $1.date }
    let firstHalf = sortedData.prefix(6).compactMap(\.averageVO2Max)
    let secondHalf = sortedData.suffix(6).compactMap(\.averageVO2Max)
    guard !firstHalf.isEmpty, !secondHalf.isEmpty else { return nil }

    let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
    let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
    let change = secondAvg - firstAvg

    if change > 1 { return .improving }
    else if change < -1 { return .declining }
    else { return .stable }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      CardioFitnessStoryPage(stats: .preview)
    }
  }
}
