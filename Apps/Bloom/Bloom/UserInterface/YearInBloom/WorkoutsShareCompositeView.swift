//
//  WorkoutsShareCompositeView.swift
//  Bloom
//
//  Created by Claude on 2025-12-19.
//

import SwiftUI
import CoreHealth
import BloomUI
import SFSafeSymbols

/// Composite view for workouts share image that combines physics bubbles snapshot with bottom content
struct WorkoutsShareCompositeView: View {
  let bubblesImage: UIImage
  let stats: YearInBloomWorkoutStats
  let appIcon: ImageResource

  var body: some View {
    ZStack {
      // Bubbles image as background (aligned to top)
      Image(uiImage: bubblesImage)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

      // Bottom solid area
      Rectangle()
        .fill(.black)
        .frame(height: 100)
        .zStackAlignment(.bottom)

      // Bottom content with gradient overlay
      VStack(spacing: 0) {
        LinearGradient(colors: [.black, .clear], startPoint: .bottom, endPoint: .top)
          .frame(height: 150)

        VStack(spacing: 32) {
          VStack {
            Image(systemSymbol: .figureRun)
              .foregroundStyle(.green)
              .font(.system(size: 50))
              .padding(.vertical)

            focusSentence
              .font(.title)
              .fontWeight(.bold)
              .fontDesign(.rounded)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)
          }

          VStack(spacing: 16) {
            statsGrid
            watermark
          }
          .padding(.bottom, 8)
        }
        .padding(.horizontal)
        .background(.black)
      }
      .zStackAlignment(.bottom)
    }
    .background(.black)
    .environment(\.colorScheme, .dark)
  }

  private var focusSentence: Text {
    let minutes = Text(formattedMinutes).foregroundStyle(.green)
    let calories = Text("\(formattedCalories) cals").foregroundStyle(.green)

    return Text(
      "You exercised for \(minutes) and burned \(calories) this year!",
      comment: "Year in Bloom workout summary. Placeholders are a duration and a calorie amount."
    )
  }

  private var statsGrid: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
      statCard(
        icon: .figureHighintensityIntervaltraining,
        value: "\(stats.yearTotals.totalWorkouts)",
        label: "Workouts"
      )
      statCard(
        icon: .clockFill,
        value: formattedAvgDuration,
        label: "Avg Duration"
      )
      statCard(
        icon: .figureTennis,
        value: "\(stats.yearTotals.uniqueWorkoutTypes)",
        label: "Types"
      )
      statCard(
        icon: .flameFill,
        value: "\(stats.longestStreak.longestStreakDays) days",
        label: "Best Streak"
      )
    }
  }

  private func statCard(icon: SFSymbol, value: String, label: String) -> some View {
    HStack {
      Image(systemSymbol: icon)
        .foregroundStyle(.green)
        .font(.title2)
      VStack(alignment: .leading, spacing: 0) {
        Text(value)
          .font(.title3)
          .bold()
        Text(label)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
    }
    .padding()
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }

  private var watermark: some View {
    HStack(spacing: 4) {
      Image(appIcon)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 20, height: 20)
        .clipShape(RoundedRectangle(cornerRadius: 4))
      Text("Year In Bloom")
        .font(.caption)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.white)
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

  private var formattedAvgDuration: String {
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
    WorkoutsShareCompositeView(
      bubblesImage: .budCoach,
      stats: .preview,
      appIcon: .bloomDisplayAppIconBlue
    )
  }
}
