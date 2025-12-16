//
//  YearInBloomActivitySection.swift
//  Bloom
//
//  Created by Claude on 2025-12-12.
//

import SwiftUI
import Charts
import CoreHealth

/// Activity Volume Trend Section
/// Shows monthly workout count and duration as line charts
struct YearInBloomActivitySection: View {
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

private extension YearInBloomActivitySection {

  var headerSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Your Year in Motion")
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

private extension YearInBloomActivitySection {

  var chartSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Workout Count Chart
      workoutCountChart
        .cardContainer()

      // Duration Chart
      durationChart
        .cardContainer()
    }
  }

  var workoutCountChart: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Circle()
          .fill(.mutedGreen)
          .frame(width: 10, height: 10)
        Text("Workouts per Month")
          .font(.subheadline)
          .fontDesign(.rounded)
          .foregroundStyle(.secondary)
      }

      Chart {
        ForEach(stats.monthlyWorkoutCounts(), id: \.date) { sample in
          LineMark(
            x: .value("Month", sample.date),
            y: .value("Workouts", sample.value)
          )
          .interpolationMethod(.catmullRom)
          .foregroundStyle(.mutedGreen)
          .lineStyle(StrokeStyle(lineWidth: 3))

          PointMark(
            x: .value("Month", sample.date),
            y: .value("Workouts", sample.value)
          )
          .foregroundStyle(isPeakMonthByCount(sample) ? .yellow : .mutedGreen)
          .symbolSize(isPeakMonthByCount(sample) ? 100 : 40)
        }
      }
      .chartXAxis {
        AxisMarks(values: .stride(by: .month)) { _ in
          AxisValueLabel(format: .dateTime.month(.abbreviated))
        }
      }
      .chartYAxis {
        AxisMarks { _ in
          AxisGridLine()
            .foregroundStyle(.secondary.opacity(0.3))
        }
      }
      .frame(height: 150)
    }
    .padding(.vertical, 8)
  }

  var durationChart: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Circle()
          .fill(.mutedTeal)
          .frame(width: 10, height: 10)
        Text("Hours per Month")
          .font(.subheadline)
          .fontDesign(.rounded)
          .foregroundStyle(.secondary)
      }

      Chart {
        ForEach(stats.monthlyDurationHours(), id: \.date) { sample in
          LineMark(
            x: .value("Month", sample.date),
            y: .value("Hours", sample.value)
          )
          .interpolationMethod(.catmullRom)
          .foregroundStyle(.mutedTeal)
          .lineStyle(StrokeStyle(lineWidth: 3))

          PointMark(
            x: .value("Month", sample.date),
            y: .value("Hours", sample.value)
          )
          .foregroundStyle(isPeakMonthByDuration(sample) ? .yellow : .mutedTeal)
          .symbolSize(isPeakMonthByDuration(sample) ? 100 : 40)
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
              Text("\(Int(doubleValue))h")
            }
          }
        }
      }
      .frame(height: 150)
    }
    .padding(.vertical, 8)
  }

  func isPeakMonthByCount(_ sample: DateValueSample) -> Bool {
    guard let peakMonth = stats.peakMonthByCount else { return false }
    let sampleMonth = Calendar.current.component(.month, from: sample.date)
    return peakMonth.month == sampleMonth && peakMonth.workoutCount == Int(sample.value)
  }

  func isPeakMonthByDuration(_ sample: DateValueSample) -> Bool {
    guard let peakMonth = stats.peakMonthByDuration else { return false }
    let sampleMonth = Calendar.current.component(.month, from: sample.date)
    return peakMonth.month == sampleMonth
  }
}

// MARK: - Insight Section

private extension YearInBloomActivitySection {

  var insightSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Big stat
      VStack(alignment: .leading, spacing: 4) {
        Text("\(stats.yearTotals.totalWorkouts)")
          .font(.system(size: 56))
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.mutedGreen)

        Text("total workouts")
          .font(.title3)
          .fontDesign(.rounded)
          .foregroundStyle(.secondary)
      }

      // Peak month callout
      if let peakMonth = stats.peakMonthByCount {
        HStack(spacing: 8) {
          Image(systemName: "star.fill")
            .foregroundStyle(.yellow)

          Text("You peaked in **\(peakMonth.monthName)** with \(peakMonth.workoutCount) workouts")
            .font(.body)
            .fontDesign(.rounded)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
      }
    }
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    YearInBloomActivitySection(stats: .preview)
  }
}
