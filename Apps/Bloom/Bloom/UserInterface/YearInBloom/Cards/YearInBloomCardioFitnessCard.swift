//
//  YearInBloomCardioFitnessCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-16.
//

import SwiftUI
import Charts
import CoreHealth

struct YearInBloomCardioFitnessCard: View {
  let stats: YearInBloomWorkoutStats

  var body: some View {
    YearInBloomCard(
      title: "Cardio Fitness",
      focusStat: stats.currentCardioFitnessLevel?.name ?? "Unknown",
      focusStatLabel: formattedLatestVO2Max,
      includeDivider: false,
      foregroundFill: .white,
      backgroundFill: .black
    ) {
      vo2MaxChart
    }
  }
}

// MARK: - Chart

private extension YearInBloomCardioFitnessCard {

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
          y: .value("VO2 Max", data.averageVO2Max ?? 0)
        )
        .foregroundStyle(yearlyAverageColor)
        .interpolationMethod(.catmullRom)
        .lineStyle(StrokeStyle(lineWidth: 2))

        PointMark(
          x: .value("Month", data.date, unit: .month),
          y: .value("VO2 Max", data.averageVO2Max ?? 0)
        )
        .symbol {
          Circle()
            .strokeBorder(yearlyAverageColor, lineWidth: 2)
            .background(Circle().fill(.black))
            .frame(width: 8, height: 8)
        }
      }
    }
    .chartYScale(domain: minVO2Max...maxVO2Max)
    .chartXScale(domain: yearStart...yearEnd)
    .chartXAxis {
      AxisMarks(values: .stride(by: .month)) { _ in
        AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
          .foregroundStyle(.secondary)
      }
    }
    .chartYAxis {
      AxisMarks(values: [minVO2Max, (minVO2Max + maxVO2Max) / 2, maxVO2Max]) { value in
        AxisGridLine()
          .foregroundStyle(.secondary)
        if let doubleValue = value.as(Double.self) {
          AxisValueLabel {
            Text("\(Int(doubleValue))")
          }
        }
      }
    }
    .chartLegend(.hidden)
    .frame(height: 200)
    .foregroundStyle(.white)
    .environment(\.colorScheme, .dark)
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
    guard !values.isEmpty else { return .white }
    let average = values.reduce(0, +) / Double(values.count)

    guard let thresholds = vo2MaxThresholds else { return .white }
    let level: HeartHealthMonthlySummary.CardioFitnessLevel
    if average < thresholds.2 { level = .low }
    else if average < thresholds.1 { level = .belowAverage }
    else if average < thresholds.0 { level = .aboveAverage }
    else { level = .high }

    return level.color
  }
}

// MARK: - Helpers

private extension YearInBloomCardioFitnessCard {

  var formattedLatestVO2Max: String {
    guard let vo2Max = stats.latestVO2Max else { return "—" }
    return String(format: "%.1f vO₂ Max", vo2Max)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      YearInBloomCardioFitnessCard(
        stats: .preview
      )
    }
  }
}
