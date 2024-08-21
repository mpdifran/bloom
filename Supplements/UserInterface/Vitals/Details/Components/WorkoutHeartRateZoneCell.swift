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
            Image(systemName: report.workouts.first?.workoutActivityType.systemImage ?? "")
                .font(.largeTitle)
                .minimumScaleFactor(0.3)
                .foregroundStyle(.green)
                .frame(width: 60)

            VStack(alignment: .leading) {
                Text(report.workouts.first?.workoutActivityType.name ?? "")
                    .font(.title3)
                    .bold()

                Text("\(report.workouts.count) \(report.workouts.count == 1 ? "time" : "times")")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            MiniTargetHeartRateZoneDistributionView(distribution: report.heartRateDistribution())
                .frame(width: 80)
        }
    }
}

#Preview {
    ScrollView {
        WorkoutHeartRateZoneCell(
            report: .init(
                workouts: [HKWorkout(
                    activityType: .cycling,
                    start: .now,
                    end: .now.addingTimeInterval(
                        3600
                    )
                )],
                heartRateSamples: [
                    HKQuantitySample(
                        type: HKQuantityType(.heartRate),
                        quantity: HKQuantity(unit: .bpm(), doubleValue: 112),
                        start: .now,
                        end: .now
                    ),
                    HKQuantitySample(
                        type: HKQuantityType(.heartRate),
                        quantity: HKQuantity(unit: .bpm(), doubleValue: 136),
                        start: .now,
                        end: .now
                    ),
                    HKQuantitySample(
                        type: HKQuantityType(.heartRate),
                        quantity: HKQuantity(unit: .bpm(), doubleValue: 142),
                        start: .now,
                        end: .now
                    )
                ],
                heartRateZones: .init(
                    heartRateReserve: 118,
                    restingHeartRate: 66,
                    maxHeartRate: 184,
                    zone1: 92,
                    zone2: 110,
                    zone3: 129,
                    zone4: 147,
                    zone5: 166
                )
            )
        )
        .cardContainer(fill: .background.secondary)
        .padding()
    }
}
