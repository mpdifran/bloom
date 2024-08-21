//
//  TargetHeartRateZonesDistributionView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-20.
//

import SwiftUI
import HealthKit

private extension CGFloat {
    static let spacing: CGFloat = 30
    static let barHeight: CGFloat = 10
}

struct TargetHeartRateZonesDistributionView: View {
    let distribution: WorkoutHeartRateReport.WorkoutHeartZoneDistribution

    var body: some View {
        VStack(spacing: .spacing) {

            HeartRateZoneBar(
                title: "Zone 1",
                duration: distribution.zone1,
                totalDuration: distribution.totalDuration,
                maxProportion: distribution.maxPercent,
                targetDurationMinutes: nil
            )
            .frame(height: .barHeight)
            .tint(.heartRateZone1)

            HeartRateZoneBar(
                title: "Zone 2",
                duration: distribution.zone2,
                totalDuration: distribution.totalDuration,
                maxProportion: distribution.maxPercent,
                targetDurationMinutes: .minZone2Minutes
            )
            .frame(height: .barHeight)
            .tint(.heartRateZone2)

            HeartRateZoneBar(
                title: "Zone 3",
                duration: distribution.zone3,
                totalDuration: distribution.totalDuration,
                maxProportion: distribution.maxPercent,
                targetDurationMinutes: .minZone3Minutes
            )
            .frame(height: .barHeight)
            .tint(.heartRateZone3)

            HeartRateZoneBar(
                title: "Zone 4",
                duration: distribution.zone4,
                totalDuration: distribution.totalDuration,
                maxProportion: distribution.maxPercent,
                targetDurationMinutes: .minZone4Minutes
            )
            .frame(height: .barHeight)
            .tint(.heartRateZone4)

            HeartRateZoneBar(
                title: "Zone 5",
                duration: distribution.zone5,
                totalDuration: distribution.totalDuration,
                maxProportion: distribution.maxPercent,
                targetDurationMinutes: .minZone5Minutes
            )
            .frame(height: .barHeight)
            .tint(.heartRateZone5)
        }
    }
}

struct HeartRateZoneBar: View {
    let title: String
    let duration: HKQuantity
    let totalDuration: HKQuantity
    let maxProportion: Double
    let targetDurationMinutes: Double?

    var body: some View {
        HStack {
            Text(title)
                .bold()
                .foregroundStyle(.tint)

            GeometryReader { proxy in
                Capsule()
                    .fill(.tint)
                    .frame(width: ((duration.doubleValue(for: .second()) / totalDuration.doubleValue(for: .second())) / maxProportion) * proxy.size.width)
            }

            VStack(alignment: .trailing) {
                Text(formattedDuration)
                if let targetDurationMinutes {
                    Text("/ \(formattedTarget(target: targetDurationMinutes))")
                        .foregroundStyle(.secondary)
                }
            }
            .bold()
            .font(.caption)
        }
    }

    var formattedDuration: String {
        let dateComponents = DateComponents(second: Int(duration.doubleValue(for: .second())))
        return DateFormatter.timeIntervalHourMinuteShort.string(from: dateComponents) ?? ""
    }

    func formattedTarget(target: Double) -> String {
        let dateComponents = DateComponents(minute: Int(target))
        return DateFormatter.timeIntervalHourMinuteShort.string(from: dateComponents) ?? ""
    }
}

#Preview {
    ScrollView {
        TargetHeartRateZonesDistributionView(
            distribution: .init(
                totalDuration: .init(unit: .minute(), doubleValue: 30),
                zone1: .init(unit: .minute(), doubleValue: 3),
                zone2: .init(unit: .minute(), doubleValue: 8),
                zone3: .init(unit: .minute(), doubleValue: 9),
                zone4: .init(unit: .minute(), doubleValue: 6),
                zone5: .init(unit: .minute(), doubleValue: 4)
            )
        )
        .cardContainer(fill: .background.secondary)
        .padding()
    }
}
