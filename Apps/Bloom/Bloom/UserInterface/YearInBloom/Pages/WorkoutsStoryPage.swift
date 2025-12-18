//
//  WorkoutsStoryPage.swift
//  Bloom
//
//  Created by Claude on 2025-12-18.
//

import SwiftUI
import CoreHealth
import SFSafeSymbols

struct WorkoutsStoryPage: View, StoryPage {
  let stats: YearInBloomWorkoutStats

  var focusSentence: Text {
    Text("You exercised for ")
      .foregroundStyle(.secondary) +
    Text(formattedMinutes)
      .foregroundStyle(.green) +
    Text(" this year")
      .foregroundStyle(.secondary)
  }

  var mainContent: some View {
    VStack(spacing: 20) {
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        statCard(label: "Workouts", value: "\(stats.yearTotals.totalWorkouts)", icon: .flameFill)
        statCard(label: "Calories", value: formattedCalories, icon: .boltFill)
        statCard(label: "Types", value: "\(stats.yearTotals.uniqueWorkoutTypes)", icon: .figureRun)
        statCard(label: "Best Streak", value: "\(stats.longestStreak.longestStreakDays) days", icon: .calendarBadgeClock)
      }
      .padding(.horizontal, 24)
    }
  }

  private var formattedMinutes: String {
    let hours = Int(stats.yearTotals.totalDurationMinutes / 60)
    if hours > 0 {
      return "\(hours.formatted()) hours"
    }
    return "\(Int(stats.yearTotals.totalDurationMinutes).formatted()) minutes"
  }

  private var formattedCalories: String {
    Int(stats.yearTotals.totalCaloriesBurned).formatted()
  }

  private func statCard(label: String, value: String, icon: SFSymbol) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Image(systemSymbol: icon)
        .font(.title2)
        .foregroundStyle(.secondary)

      Text(value)
        .font(.title2)
        .bold()
        .fontDesign(.rounded)

      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
  }
}

#Preview {
  PreviewEnvironment {
    WorkoutsStoryPage(stats: .preview)
  }
}
