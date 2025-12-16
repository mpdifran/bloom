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
      focusStat: formattedLatestVO2Max,
      focusStatLabel: stats.currentCardioFitnessLevel?.name ?? "Unknown",
      includeDivider: false
    ) {
      vo2MaxChart
    }
  }
}

// MARK: - Chart

private extension YearInBloomCardioFitnessCard {

  var vo2MaxChart: some View {
    Chart {
      ForEach(monthlyDataWithValues) { data in
        LineMark(
          x: .value("Month", data.date, unit: .month),
          y: .value("VO2 Max", data.averageVO2Max ?? 0)
        )
        .foregroundStyle(colorForLevel(data.cardioFitnessLevel))
        .interpolationMethod(.catmullRom)
        .lineStyle(StrokeStyle(lineWidth: 2))

        PointMark(
          x: .value("Month", data.date, unit: .month),
          y: .value("VO2 Max", data.averageVO2Max ?? 0)
        )
        .symbol {
          Circle()
            .strokeBorder(colorForLevel(data.cardioFitnessLevel), lineWidth: 2)
            .background(Circle().fill(.background))
            .frame(width: 8, height: 8)
        }
      }
    }
    .chartXAxis {
      AxisMarks(values: .stride(by: .month)) { _ in
        AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
      }
    }
    .chartYAxis {
      AxisMarks { value in
        AxisGridLine()
        if let doubleValue = value.as(Double.self) {
          AxisValueLabel {
            Text("\(Int(doubleValue))")
          }
        }
      }
    }
    .chartLegend(.hidden)
    .frame(height: 140)
  }

  var monthlyDataWithValues: [MonthlyVO2MaxData] {
    stats.monthlyVO2Max.filter { $0.averageVO2Max != nil }
  }

  func colorForLevel(_ level: HeartHealthMonthlySummary.CardioFitnessLevel?) -> Color {
    guard let level else { return .mutedRed }
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
