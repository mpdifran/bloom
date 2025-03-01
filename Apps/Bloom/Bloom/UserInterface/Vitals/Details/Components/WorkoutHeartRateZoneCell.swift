//
//  WorkoutHeartRateZoneCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-21.
//

import SwiftUI
import HealthKit

struct WorkoutHeartRateZoneCell: View {
  let report: WorkoutTypeHeartRateReport

  var body: some View {
    HStack {
      Image(systemName: report.activityType.systemImage)
        .font(.largeTitle)
        .minimumScaleFactor(0.3)
        .foregroundStyle(.green)
        .frame(width: 60)

      VStack(alignment: .leading, spacing: 4) {
        Text(report.activityType.name)
          .font(.headline)
          .bold()

        VStack(alignment: .leading) {
          Text("\(report.heartZoneDistribution.scaledDurationSum.displayString(for: .minute(), formatter: .noDecimalPlaces)) zone minutes")
          Text("\(report.workoutCount) \(report.workoutCount == 1 ? "time" : "times")")
        }
        .bold()
        .font(.subheadline)
        .foregroundStyle(.secondary)
      }
      .multilineTextAlignment(.leading)

      Spacer()

      MiniTargetHeartRateZoneDistributionView(distribution: report.heartZoneDistribution)
        .frame(width: 80)

      DisclosureIndicator()
    }
  }
}

#Preview {
  ScrollView {
    VStack {
      WorkoutHeartRateZoneCell(
        report: WorkoutTypeHeartRateReport(
          activityType: .bowling,
          workoutCount: 3,
          heartZoneDistribution: WorkoutHeartRateReport.WorkoutHeartZoneDistribution(
            totalDuration: HKQuantity(unit: .minute(), doubleValue: 30),
            zone1: HKQuantity(unit: .minute(), doubleValue: 9),
            zone2: HKQuantity(unit: .minute(), doubleValue: 7),
            zone3: HKQuantity(unit: .minute(), doubleValue: 5),
            zone4: HKQuantity(unit: .minute(), doubleValue: 5),
            zone5: HKQuantity(unit: .minute(), doubleValue: 4)
          )
        )
      )
      .cardContainer(fill: .background.secondary)

      WorkoutHeartRateZoneCell(
        report: WorkoutTypeHeartRateReport(
          activityType: .walking,
          workoutCount: 4,
          heartZoneDistribution: WorkoutHeartRateReport.WorkoutHeartZoneDistribution(
            totalDuration: HKQuantity(unit: .minute(), doubleValue: 30),
            zone1: HKQuantity(unit: .minute(), doubleValue: 0),
            zone2: HKQuantity(unit: .minute(), doubleValue: 0),
            zone3: HKQuantity(unit: .minute(), doubleValue: 0),
            zone4: HKQuantity(unit: .minute(), doubleValue: 0),
            zone5: HKQuantity(unit: .minute(), doubleValue: 0)
          )
        )
      )
      .cardContainer(fill: .background.secondary)
    }
    .padding()
  }
}
