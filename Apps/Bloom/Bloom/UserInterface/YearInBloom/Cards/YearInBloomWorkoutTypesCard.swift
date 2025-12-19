//
//  YearInBloomWorkoutTypesCard.swift
//  Bloom
//
//  Created by Claude on 2025-12-18.
//

import SwiftUI
import UIKit
import CoreHealth
import BloomUI
import SFSafeSymbols
import HealthKit

// MARK: - Main Card View

struct YearInBloomWorkoutTypesCard: View {
  let stats: YearInBloomWorkoutStats

  @State private var selectedWorkoutStats: WorkoutTypeStats?

  var body: some View {
    YearInBloomCard(
      title: "Workouts",
      focusStat: formattedTotalMinutes,
      focusStatLabel: "Total Minutes",
      includePadding: false,
      includeDivider: false,
      backgroundFill: .background.secondary
    ) {
      VStack(spacing: 12) {
        WorkoutBubblesView(
          workoutTypes: stats.topWorkoutTypes,
          onBubbleTap: { tappedStats in
            withAnimation(.bouncy) {
              if selectedWorkoutStats == tappedStats {
                selectedWorkoutStats = nil
              } else {
                selectedWorkoutStats = tappedStats
              }
            }
          }
        )
        .frame(height: 220)
        .padding(.horizontal)

        WorkoutDetailCard(
          selectedWorkoutStats: selectedWorkoutStats,
          yearTotals: stats.yearTotals,
          totalDistance: stats.totalDistanceMeters
        )
        .padding(.horizontal)
        .padding(.bottom)
        .animation(.bouncy, value: selectedWorkoutStats)
      }
    }
    .sensoryFeedback(.selection, trigger: selectedWorkoutStats)
  }

  private var formattedTotalMinutes: String {
    let minutes = Int(stats.yearTotals.totalDurationMinutes)
    return minutes.formatted()
  }
}

// MARK: - Detail Card

private struct WorkoutDetailCard: View {
  let selectedWorkoutStats: WorkoutTypeStats?
  let yearTotals: YearTotals
  let totalDistance: Double

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        if let selected = selectedWorkoutStats {
          Image(systemName: selected.activityType.systemImage)
            .font(.title2)
          Text(selected.activityName)
            .font(.headline)
            .fontDesign(.rounded)
        } else {
          Image(systemName: "figure.run.circle.fill")
            .font(.title2)
          Text("All Workouts")
            .font(.headline)
            .fontDesign(.rounded)
        }
        Spacer()
      }

      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
        statCard(label: "Duration", value: formattedDuration, symbol: .clockFill)
        statCard(label: "Workouts", value: formattedWorkoutCount, symbol: .flameFill)
        statCard(label: "Calories", value: formattedCalories, symbol: .boltFill)

        if distanceValue > 0 {
          statCard(label: "Distance", value: formattedDistance, symbol: .locationFill)
        }

        if let zoneMinutes = zoneMinutesValue, zoneMinutes > 0 {
          statCard(label: "Zone Min", value: "\(Int(zoneMinutes))", symbol: .heartFill)
        }
      }
    }
    .padding(12)
    .background(.background, in: RoundedRectangle(cornerRadius: 14))
  }

  private func statCard(label: String, value: String, symbol: SFSymbol) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Label(label, systemSymbol: symbol)
        .font(.caption)
        .foregroundStyle(.secondary)

      Spacer()

      Text(value)
        .font(.title3)
        .bold()
        .fontDesign(.rounded)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(minHeight: 50)
    .padding(10)
    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
  }

  // MARK: - Computed Values

  private var durationMinutes: Double {
    selectedWorkoutStats?.totalDurationMinutes ?? yearTotals.totalDurationMinutes
  }

  private var formattedDuration: String {
    let hours = Int(durationMinutes / 60)
    let minutes = Int(durationMinutes.truncatingRemainder(dividingBy: 60))
    if hours > 0 {
      return "\(hours)h \(minutes)m"
    }
    return "\(minutes)m"
  }

  private var formattedWorkoutCount: String {
    let count = selectedWorkoutStats?.count ?? yearTotals.totalWorkouts
    return "\(count)"
  }

  private var formattedCalories: String {
    let calories = selectedWorkoutStats?.totalCaloriesBurned ?? yearTotals.totalCaloriesBurned
    return Int(calories).formatted()
  }

  private var distanceValue: Double {
    selectedWorkoutStats?.totalDistanceMeters ?? totalDistance
  }

  private var formattedDistance: String {
    let km = distanceValue / 1000
    if km >= 100 {
      return "\(Int(km)) km"
    }
    return String(format: "%.1f km", km)
  }

  private var zoneMinutesValue: Double? {
    if let selected = selectedWorkoutStats {
      return selected.zoneMinutes?.scaledZoneMinutes
    }
    return yearTotals.totalZoneMinutes?.scaledZoneMinutes
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      YearInBloomWorkoutTypesCard(stats: .preview)
    }
  }
}
