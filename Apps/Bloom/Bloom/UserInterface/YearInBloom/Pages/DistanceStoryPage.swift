//
//  DistanceStoryPage.swift
//  Bloom
//
//  Created by Claude on 2025-12-18.
//

import SwiftUI
import Charts
import CoreHealth
import BloomUI
import HealthKit
import SFSafeSymbols
import BloomFoundation

struct DistanceStoryPage: View {
  let stats: YearInBloomWorkoutStats

  var body: some View {
    VStack {
      Spacer()

      stepsSection
        .padding(.bottom)

      Spacer()

      Image(systemSymbol: .figureWalk)
        .foregroundStyle(.tint)
        .font(.system(size: 50))
        .contentTransition(.symbolEffect)
        .padding(.bottom)

      focusSection
        .fixedSize(horizontal: false, vertical: true)

      Spacer()

      distanceChart
    }
    .padding()
    .tint(.mutedYellow)
    .toolbar {
      ToolbarItem(placement: .principal) {
        titleView
      }
    }
  }

  private var focusSentence: Text {
    let distance = Text(formattedTotalDistance).foregroundStyle(.tint)
    let base = Text(
      "You travelled \(distance) while working out this year.",
      comment: "Year in Bloom distance summary. The placeholder is a total distance."
    )

    if let comparison = distanceComparison {
      return Text(
        "\(base) \(comparison)",
        comment: "Year in Bloom distance summary followed by a comparison sentence."
      )
    }
    return base
  }

  private var focusSection: some View {
    focusSentence
      .font(.title)
      .fontWeight(.bold)
      .fontDesign(.rounded)
      .multilineTextAlignment(.center)
  }
}

// MARK: - Title & Chart

private extension DistanceStoryPage {

  var titleView: some View {
    Text("Distance")
      .font(.title3)
      .fontDesign(.rounded)
      .bold()
  }

  var distanceChart: some View {
    Chart {
      ForEach(workoutTypesByDistance) { workoutType in
        BarMark(
          x: .value("Distance", distanceInUserUnits(workoutType.totalDistanceMeters ?? 0)),
          y: .value("Type", workoutType.activityName)
        )
        .foregroundStyle(.tint)
        .clipShape(Capsule())
        .annotation(position: .trailing, alignment: .leading, spacing: 4) {
          Text(formattedDistance(workoutType.totalDistanceMeters ?? 0))
            .font(.caption2)
            .fontDesign(.rounded)
            .bold()
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

// MARK: - Stats Grid

private extension DistanceStoryPage {

  var stepsSection: some View {
    VStack(spacing: 4) {
      Group {
        if let steps = stats.yearTotals.totalSteps {
          Text(steps.formatted())
        } else {
          Text(verbatim: "—-")
        }
      }
      .lineLimit(1)
      .font(.system(size: 100))
      .bold()
      .fontDesign(.rounded)
      .minimumScaleFactor(0.6)
      .foregroundStyle(.tint)
      Text("steps")
        .font(.title)
        .bold()
    }
    .fontDesign(.rounded)
    .padding(.horizontal)
  }
}

// MARK: - Helpers

private extension DistanceStoryPage {

  var workoutTypesByDistance: [WorkoutTypeStats] {
    stats.workoutTypesByDistance
  }

  var distanceComparison: String? {
    let totalKm = stats.totalDistanceMeters / 1000

    switch totalKm {
    case ..<50:
      return nil // Too short for meaningful comparison
    case 50..<150:
      return "That's like London to Brighton!"
    case 150..<350:
      return "That's like NYC to Boston!"
    case 350..<550:
      return "That's like Paris to Brussels!"
    case 550..<900:
      return "That's like Toronto to Montreal!"
    case 900..<1500:
      return "That's like NYC to Chicago!"
    case 1500..<3000:
      return "That's like London to Rome!"
    case 3000..<5000:
      return "That's like LA to New York!"
    case 5000..<10000:
      return "That's like crossing the Atlantic!"
    case 10000..<20000:
      return "That's like London to Tokyo!"
    case 20000..<40000:
      return "That's halfway around the Earth!"
    case 40000..<100000:
      return "That's more than once around the Earth!"
    case 100000..<384000:
      return "You're on your way to the Moon!"
    default:
      return "That's farther than the Moon!"
    }
  }

  var formattedTotalDistance: String {
    HKQuantity(unit: .meter(), doubleValue: stats.totalDistanceMeters)
      .displayString(for: .meterUnit(with: .kilo))
  }

  func distanceInUserUnits(_ meters: Double) -> Double {
    HKQuantity(unit: .meter(), doubleValue: meters)
      .localizedValue(for: .meterUnit(with: .kilo))
  }

  func formattedDistance(_ meters: Double) -> String {
    HKQuantity(unit: .meter(), doubleValue: meters)
      .displayString(for: .meterUnit(with: .kilo))
  }
}

#Preview {
  PreviewEnvironment {
    DistanceStoryPage(stats: .preview)
  }
}
