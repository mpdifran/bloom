//
//  WorkoutsStoryPage.swift
//  Bloom
//
//  Created by Claude on 2025-12-18.
//

import SwiftUI
import CoreHealth
import BloomUI
import SFSafeSymbols

struct WorkoutsStoryPage: View {
  let stats: YearInBloomWorkoutStats

  var body: some View {
    ZStack {
      WorkoutBubblesView(
        workoutTypes: stats.topWorkoutTypes,
        onBubbleTap: { _ in }
      )
      .frame(maxHeight: .infinity)

      Rectangle()
        .fill(.black)
        .frame(height: 100)
        .zStackAlignment(.bottom)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        LinearGradient(colors: [.black, .clear], startPoint: .bottom, endPoint: .top)
          .frame(height: 150)
        VStack(spacing: 40) {
          VStack {
            Image(systemSymbol: .figureRun)
              .foregroundStyle(.tint)
              .font(.system(size: 50))
              .contentTransition(.symbolEffect)
              .padding(.vertical)

            focusSentence
              .font(.title)
              .fontWeight(.bold)
              .fontDesign(.rounded)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)
          }

          statsGrid
        }
        .padding(.horizontal)
        .background {
          Rectangle()
            .fill(.black)
            .ignoresSafeArea()
        }
      }
      .zStackAlignment(.bottom)
    }
    .background {
      Rectangle()
        .fill(.black)
        .ignoresSafeArea()
    }
    .tint(.green)
    .toolbar {
      ToolbarItem(placement: .principal) {
        titleView
      }
    }
    .ignoresSafeArea(edges: .top)
    .environment(\.colorScheme, .dark)
  }

  private var focusSentence: Text {
    Text("You exercised for ") +
    Text(formattedMinutes)
      .foregroundStyle(.tint) +
    Text(" and burned ") +
    Text(formattedCalories + " cals")
      .foregroundStyle(.tint) +
    Text(" this year!")
  }
}

// MARK: - Title

private extension WorkoutsStoryPage {

  var titleView: some View {
    Text("Workouts")
      .font(.title3)
      .fontDesign(.rounded)
      .bold()
  }
}

// MARK: - Stats Grid

private extension WorkoutsStoryPage {

  var statsGrid: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
      workoutsCard
      avgDurationCard
      typesCard
      streakCard
    }
  }

  var workoutsCard: some View {
    HStack {
      Image(systemSymbol: .figureHighintensityIntervaltraining)
        .foregroundStyle(.tint)
        .font(.title2)
      VStack(alignment: .leading, spacing: 0) {
        Text("\(stats.yearTotals.totalWorkouts)")
          .font(.title3)
          .bold()
        Text("Workouts")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
    }
    .cardContainer(fill: .background.secondary)
  }

  var avgDurationCard: some View {
    HStack {
      Image(systemSymbol: .clockFill)
        .foregroundStyle(.tint)
        .font(.title2)
      VStack(alignment: .leading, spacing: 0) {
        Text(formattedAvgDuration)
          .font(.title3)
          .bold()
        Text("Avg Duration")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
    }
    .cardContainer(fill: .background.secondary)
  }

  var typesCard: some View {
    HStack {
      Image(systemSymbol: .figureTennis)
        .foregroundStyle(.tint)
        .font(.title2)
      VStack(alignment: .leading, spacing: 0) {
        Text("\(stats.yearTotals.uniqueWorkoutTypes)")
          .font(.title3)
          .bold()
        Text("Types")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
    }
    .cardContainer(fill: .background.secondary)
  }

  var streakCard: some View {
    HStack {
      Image(systemSymbol: .flameFill)
        .foregroundStyle(.tint)
        .font(.title2)
      VStack(alignment: .leading, spacing: 0) {
        Text("\(stats.longestStreak.longestStreakDays) days")
          .font(.title3)
          .bold()
        Text("Best Streak")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
    }
    .cardContainer(fill: .background.secondary)
  }
}

// MARK: - Helpers

private extension WorkoutsStoryPage {

  var formattedMinutes: String {
    let hours = Int(stats.yearTotals.totalDurationMinutes / 60)
    if hours > 0 {
      return "\(hours.formatted()) hours"
    }
    return "\(Int(stats.yearTotals.totalDurationMinutes).formatted()) minutes"
  }

  var formattedCalories: String {
    Int(stats.yearTotals.totalCaloriesBurned).formatted()
  }

  var formattedAvgDuration: String {
    let avgMinutes = stats.yearTotals.totalDurationMinutes / Double(stats.yearTotals.totalWorkouts)
    let hours = Int(avgMinutes / 60)
    let minutes = Int(avgMinutes.truncatingRemainder(dividingBy: 60))
    if hours > 0 {
      return "\(hours)h \(minutes)m"
    }
    return "\(Int(avgMinutes)) min"
  }
}

#Preview {
  PreviewEnvironment {
    WorkoutsStoryPage(stats: .preview)
  }
}
