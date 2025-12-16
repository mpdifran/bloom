//
//  YearInBloomCaloriesSection.swift
//  Bloom
//
//  Created by Claude on 2025-12-12.
//

import SwiftUI
import Charts
import CoreHealth

/// Calories Burned Section
/// Shows monthly calories burned as bar chart with rolling average trend line
struct YearInBloomCaloriesSection: View {
  let stats: YearInBloomWorkoutStats

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      headerSection
      chartSection
      insightSection
    }
  }
}

// MARK: - Header Section

private extension YearInBloomCaloriesSection {

  var headerSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Calories Crushed")
        .font(.title)
        .bold()
        .fontDesign(.rounded)

      Text("\(stats.year)")
        .font(.title2)
        .foregroundStyle(.secondary)
        .fontDesign(.rounded)
    }
  }
}

// MARK: - Chart Section

private extension YearInBloomCaloriesSection {

  var chartSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Legend
      HStack(spacing: 16) {
        HStack(spacing: 4) {
          RoundedRectangle(cornerRadius: 2)
            .fill(.mutedPink)
            .frame(width: 12, height: 12)
          Text("Monthly")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        HStack(spacing: 4) {
          RoundedRectangle(cornerRadius: 2)
            .fill(.mutedRed)
            .frame(width: 12, height: 4)
          Text("3-Month Avg")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .fontDesign(.rounded)

      // Chart
      Chart {
        // Bar marks for monthly calories
        ForEach(stats.monthlyCalories(), id: \.date) { sample in
          BarMark(
            x: .value("Month", sample.date, unit: .month),
            y: .value("Calories", sample.value)
          )
          .foregroundStyle(.mutedPink.opacity(0.8))
          .cornerRadius(4)
        }

        // Line mark for 3-month rolling average
        ForEach(rollingAverageData, id: \.date) { sample in
          LineMark(
            x: .value("Month", sample.date),
            y: .value("Average", sample.value)
          )
          .interpolationMethod(.catmullRom)
          .foregroundStyle(.mutedRed)
          .lineStyle(StrokeStyle(lineWidth: 3))
        }
      }
      .chartXAxis {
        AxisMarks(values: .stride(by: .month)) { _ in
          AxisValueLabel(format: .dateTime.month(.abbreviated))
        }
      }
      .chartYAxis {
        AxisMarks { value in
          AxisGridLine()
            .foregroundStyle(.secondary.opacity(0.3))
          if let doubleValue = value.as(Double.self) {
            AxisValueLabel {
              Text(formatCalories(doubleValue))
            }
          }
        }
      }
      .frame(height: 220)
    }
    .padding()
    .cardContainer()
  }

  var rollingAverageData: [DateValueSample] {
    let monthlyData = stats.monthlyCalories()
    let values = monthlyData.map(\.value)
    let averages = values.rollingAverage(windowSize: 3)

    return zip(monthlyData, averages).map { sample, avg in
      DateValueSample(date: sample.date, value: avg)
    }
  }

  func formatCalories(_ value: Double) -> String {
    if value >= 1000 {
      return String(format: "%.0fk", value / 1000)
    }
    return "\(Int(value))"
  }
}

// MARK: - Insight Section

private extension YearInBloomCaloriesSection {

  var insightSection: some View {
    VStack(alignment: .leading, spacing: 20) {
      // Big stat
      VStack(alignment: .leading, spacing: 4) {
        Text(formattedTotalCalories)
          .font(.system(size: 48))
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.mutedPink)

        Text("calories burned")
          .font(.title3)
          .fontDesign(.rounded)
          .foregroundStyle(.secondary)
      }

      // Fun comparison
      comparisonCard
    }
  }

  var formattedTotalCalories: String {
    let total = stats.yearTotals.totalCaloriesBurned
    if total >= 1000 {
      return String(format: "%.1fk", total / 1000)
    }
    return "\(Int(total))"
  }

  var comparisonCard: some View {
    HStack(spacing: 12) {
      let comparison = CalorieComparison.bestComparison(for: stats.yearTotals.totalCaloriesBurned)

      Text(comparison.emoji)
        .font(.system(size: 32))

      VStack(alignment: .leading, spacing: 2) {
        Text("That's equivalent to")
          .font(.caption)
          .foregroundStyle(.secondary)

        Text("**\(comparison.equivalentUnits(for: stats.yearTotals.totalCaloriesBurned).formatted()) \(comparison.unitName(for: comparison.equivalentUnits(for: stats.yearTotals.totalCaloriesBurned)))**")
          .font(.headline)
      }
      .fontDesign(.rounded)

      Spacer()
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(Color.mutedPink.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    YearInBloomCaloriesSection(stats: .preview)
  }
}
