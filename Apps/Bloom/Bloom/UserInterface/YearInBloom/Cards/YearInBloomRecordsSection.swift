//
//  YearInBloomRecordsSection.swift
//  Bloom
//
//  Created by Claude on 2025-12-12.
//

import SwiftUI
import Charts
import CoreHealth

/// Records & Streaks Section
/// Shows best month, longest streak, favorite workout, and month comparison
struct YearInBloomRecordsSection: View {
  let stats: YearInBloomWorkoutStats

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      headerSection
      highlightSection
      chartSection
      statsGridSection
    }
  }
}

// MARK: - Header Section

private extension YearInBloomRecordsSection {

  var headerSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Most Dedicated")
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

// MARK: - Highlight Section

private extension YearInBloomRecordsSection {

  var highlightSection: some View {
    Group {
      if let bestMonth = stats.bestMonth {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Image(systemName: "trophy.fill")
              .font(.title2)
              .foregroundStyle(.yellow)

            Text("Your Best Month")
              .font(.headline)
              .fontDesign(.rounded)
          }

          Text(bestMonth.monthName)
            .font(.system(size: 44))
            .bold()
            .fontDesign(.rounded)
            .foregroundStyle(.mutedGreen)

          Text("\(bestMonth.workoutCount) workouts • \(formatDuration(bestMonth.totalDurationMinutes))")
            .font(.subheadline)
            .fontDesign(.rounded)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mutedGreen.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
      }
    }
  }

  func formatDuration(_ minutes: Double) -> String {
    let hours = Int(minutes / 60)
    let mins = Int(minutes.truncatingRemainder(dividingBy: 60))
    if hours > 0 {
      return "\(hours)h \(mins)m"
    }
    return "\(mins)m"
  }
}

// MARK: - Chart Section

private extension YearInBloomRecordsSection {

  var chartSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Monthly Activity")
        .font(.subheadline)
        .fontDesign(.rounded)
        .foregroundStyle(.secondary)

      Chart {
        ForEach(stats.monthlyStats) { monthly in
          let date = Calendar.current.date(from: DateComponents(year: stats.year, month: monthly.month, day: 15)) ?? .now
          let isBestMonth = stats.bestMonth?.month == monthly.month

          BarMark(
            x: .value("Month", date, unit: .month),
            y: .value("Hours", monthly.totalDurationMinutes / 60)
          )
          .foregroundStyle(isBestMonth ? .mutedGreen : .mutedGreen.opacity(0.4))
          .cornerRadius(4)
          .annotation(position: .top) {
            if isBestMonth {
              Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundStyle(.yellow)
            }
          }
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
    .padding()
    .cardContainer()
  }
}

// MARK: - Stats Grid Section

private extension YearInBloomRecordsSection {

  var statsGridSection: some View {
    VStack(spacing: 12) {
      HStack(spacing: 12) {
        streakCard
        favoriteWorkoutCard
      }

      HStack(spacing: 12) {
        totalHoursCard
        consistencyCard
      }
    }
  }

  var streakCard: some View {
    StatCard(
      icon: "flame.fill",
      iconColor: .orange,
      title: "Longest Streak",
      value: "\(stats.longestStreak.longestStreakDays)",
      subtitle: "days"
    )
  }

  var favoriteWorkoutCard: some View {
    StatCard(
      icon: "heart.fill",
      iconColor: .mutedPink,
      title: "Favorite",
      value: stats.topWorkoutTypes.first?.activityName ?? "—",
      subtitle: "\(stats.topWorkoutTypes.first?.count ?? 0) times"
    )
  }

  var totalHoursCard: some View {
    StatCard(
      icon: "clock.fill",
      iconColor: .mutedTeal,
      title: "Total Time",
      value: "\(Int(stats.yearTotals.totalDurationHours))",
      subtitle: "hours"
    )
  }

  var consistencyCard: some View {
    let monthsWithWorkouts = stats.monthlyStats.filter { $0.workoutCount > 0 }.count

    return StatCard(
      icon: "checkmark.circle.fill",
      iconColor: .mutedGreen,
      title: "Active Months",
      value: "\(monthsWithWorkouts)",
      subtitle: "of 12"
    )
  }
}

// MARK: - Stat Card Component

private struct StatCard: View {
  let icon: String
  let iconColor: Color
  let title: String
  let value: String
  let subtitle: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: icon)
          .font(.body)
          .foregroundStyle(iconColor)

        Text(title)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Text(value)
        .font(.title2)
        .bold()
        .lineLimit(1)
        .minimumScaleFactor(0.7)

      Text(subtitle)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .fontDesign(.rounded)
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(.secondarySystemGroupedBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    YearInBloomRecordsSection(stats: .preview)
  }
}
