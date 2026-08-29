//
//  YearInBloomWalkingRunningDistanceCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-16.
//

import SwiftUI
import Charts
import CoreHealth
import HealthKit

struct YearInBloomWalkingRunningDistanceCard: View {
  let stats: YearInBloomWorkoutStats

  @State private var distanceUnit: HKUnit = HealthUnitPreferences.shared.distanceUnit

  var body: some View {
    YearInBloomCard(
      title: String(localized: "Distance Moved", comment: "Year in Bloom card title"),
      focusStat: formattedTotalDistance,
      focusStatLabel: distanceUnit.sensibleUnitString,
      foregroundFill: .black,
      backgroundFill: .white
    ) {
      distanceChart
    }
    .task {
      distanceUnit = HealthUnitPreferences.shared.distanceUnit
    }
  }
}

// MARK: - Chart

private extension YearInBloomWalkingRunningDistanceCard {

  var distanceChart: some View {
    Chart {
      ForEach(workoutTypesByDistance) { workoutType in
        BarMark(
          x: .value("Distance", distanceInUserUnits(workoutType.totalDistanceMeters ?? 0)),
          y: .value("Type", workoutType.activityName)
        )
        .foregroundStyle(.black.opacity(0.8))
        .cornerRadius(8)
        .clipShape(Capsule())
        .annotation(position: .trailing, alignment: .leading, spacing: 4) {
          Text(formattedDistance(workoutType.totalDistanceMeters ?? 0))
            .font(.caption2)
            .fontDesign(.rounded)
            .bold()
            .foregroundStyle(.black)
        }
      }
    }
    .chartXAxis(.hidden)
    .chartYAxis {
      AxisMarks { value in
        AxisValueLabel {
          if let name = value.as(String.self),
             let workoutType = workoutTypesByDistance.first(where: { $0.activityName == name }) {
            HStack(spacing: 4) {
              Image(systemName: workoutType.activityType.systemImage)
              Text(name)
                .font(.caption)
                .fontDesign(.rounded)
                .bold()
                .fixedSize()
            }
            .foregroundStyle(.black)
            .font(.subheadline)
            .fontDesign(.rounded)
            .bold()
          }
        }
      }
    }
    .chartLegend(.hidden)
    .frame(height: CGFloat(workoutTypesByDistance.count) * 36)
  }
}

// MARK: - Helpers

private extension YearInBloomWalkingRunningDistanceCard {

  var workoutTypesByDistance: [WorkoutTypeStats] {
    stats.workoutTypesByDistance
  }

  var formattedTotalDistance: String {
    let totalMeters = stats.totalDistanceMeters
    let distance = distanceInUserUnits(totalMeters)
    if distance >= 1000 {
      return distance.formatted(.number.precision(.fractionLength(0)))
    } else if distance >= 100 {
      return distance.formatted(.number.precision(.fractionLength(0)))
    } else {
      return distance.formatted(.number.precision(.fractionLength(1)))
    }
  }

  func distanceInUserUnits(_ meters: Double) -> Double {
    HKQuantity(unit: .meter(), doubleValue: meters).doubleValue(for: distanceUnit)
  }

  func formattedDistance(_ meters: Double) -> String {
    let distance = distanceInUserUnits(meters)
    if distance >= 100 {
      return "\(Int(distance)) \(distanceUnit.sensibleUnitString)"
    } else {
      return "\(distance.formatted(.number.precision(.fractionLength(1)))) \(distanceUnit.sensibleUnitString)"
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      YearInBloomWalkingRunningDistanceCard(
        stats: .preview
      )
    }
  }
}
