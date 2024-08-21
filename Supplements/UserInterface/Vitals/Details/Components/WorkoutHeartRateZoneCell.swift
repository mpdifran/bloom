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

            VStack(alignment: .leading) {
                Text(report.activityType.name)
                    .font(.title3)
                    .bold()

                Text("\(report.workoutCount) \(report.workoutCount == 1 ? "time" : "times")")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            MiniTargetHeartRateZoneDistributionView(distribution: report.heartZoneDistribution)
                .frame(width: 80)
        }
    }
}

#Preview {
    ScrollView {
        WorkoutHeartRateZoneCell(
            report: .init(
                activityType: .bowling,
                workoutCount: 3,
                heartZoneDistribution: .init(
                    totalDuration: .init(unit: .minute(), doubleValue: 30),
                    zone1: .init(unit: .minute(), doubleValue: 9),
                    zone2: .init(unit: .minute(), doubleValue: 7),
                    zone3: .init(unit: .minute(), doubleValue: 5),
                    zone4: .init(unit: .minute(), doubleValue: 5),
                    zone5: .init(unit: .minute(), doubleValue: 4)
                )
            )
        )
        .cardContainer(fill: .background.secondary)
        .padding()
    }
}
