//
//  RecentWorkoutCell.swift
//  Bloom
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI
import SFSafeSymbols
import HealthKit
import CoreHealth

struct RecentWorkoutCell: View {
  let report: WorkoutHeartRateReport

  var body: some View {
    HStack {
      Circle()
        .fill(.green)
        .frame(square: 50)
        .overlay {
          Image(systemSymbol: SFSymbol(rawValue: report.workout.workoutActivityType.systemImage))
            .foregroundStyle(.black)
            .font(.system(size: 20))
        }

      VStack(alignment: .leading, spacing: 4) {
        Text(report.workout.workoutActivityType.name)
          .font(.headline)
          .bold()

        Text(DateFormatter.justRelativeDayOfWeek(date: report.workout.startDate))
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .multilineTextAlignment(.leading)

      Spacer()

      MiniTargetHeartRateZoneDistributionView(distribution: report.heartZoneDistribution)
        .frame(width: 80)

      DisclosureIndicator()
    }
    .padding()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      VStack(spacing: 0) {
        RecentWorkoutCell(
          report: WorkoutHeartRateReport(
            workout: HKWorkout(
              activityType: .running,
              start: Date().addingTimeInterval(-3600),
              end: Date()
            ),
            heartRateSamples: [],
            heartRateZones: previewHeartRateZones
          )
        )

        Divider()

        RecentWorkoutCell(
          report: WorkoutHeartRateReport(
            workout: HKWorkout(
              activityType: .cycling,
              start: Date().addingTimeInterval(-86400),
              end: Date().addingTimeInterval(-82800)
            ),
            heartRateSamples: [],
            heartRateZones: previewHeartRateZones
          )
        )
      }
      .cardContainer(includePadding: false)
    }
  }
}

private let previewHeartRateZones = HeartRateZones(
  heartRateReserve: 120,
  restingHeartRate: 60,
  maxHeartRate: 180,
  zone1: 100,
  zone2: 120,
  zone3: 140,
  zone4: 160,
  zone5: 170
)
