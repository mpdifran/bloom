//
//  MiniTargetHeartRateZoneDistributionView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-21.
//

import SwiftUI
import HealthKit

private extension CGFloat {
    static let spacing: CGFloat = 5
    static let barHeight: CGFloat = 5
}

struct MiniTargetHeartRateZoneDistributionView: View {
    let distribution: WorkoutHeartRateReport.WorkoutHeartZoneDistribution

    var body: some View {
        VStack(spacing: .spacing) {
            MiniHeartRateZoneBar(
                duration: distribution.zone1,
                totalDuration: distribution.totalDuration,
                maxProportion: distribution.maxPercent
            )
            .frame(height: .barHeight)
            .tint(.heartRateZone1)

            MiniHeartRateZoneBar(
                duration: distribution.zone2,
                totalDuration: distribution.totalDuration,
                maxProportion: distribution.maxPercent
            )
            .frame(height: .barHeight)
            .tint(.heartRateZone2)

            MiniHeartRateZoneBar(
                duration: distribution.zone3,
                totalDuration: distribution.totalDuration,
                maxProportion: distribution.maxPercent
            )
            .frame(height: .barHeight)
            .tint(.heartRateZone3)

            MiniHeartRateZoneBar(
                duration: distribution.zone4,
                totalDuration: distribution.totalDuration,
                maxProportion: distribution.maxPercent
            )
            .frame(height: .barHeight)
            .tint(.heartRateZone4)

            MiniHeartRateZoneBar(
                duration: distribution.zone5,
                totalDuration: distribution.totalDuration,
                maxProportion: distribution.maxPercent
            )
            .frame(height: .barHeight)
            .tint(.heartRateZone5)
        }
    }
}

struct MiniHeartRateZoneBar: View {
    let duration: HKQuantity
    let totalDuration: HKQuantity
    let maxProportion: Double

    var body: some View {
        HStack {
            GeometryReader { proxy in
                Capsule()
                    .fill(.tint)
                    .frame(width: width(proxy: proxy))
            }
        }
    }

    private func width(proxy: GeometryProxy) -> CGFloat {
        if duration.doubleValue(for: .second()) < 1 {
            return .barHeight
        }

        let proportionWidth = ((duration.doubleValue(for: .second()) / totalDuration.doubleValue(for: .second())) / maxProportion) * proxy.size.width

        return max(proportionWidth, 1)
    }
}

#Preview {
    ScrollView {
        VStack {
            MiniTargetHeartRateZoneDistributionView(
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

            MiniTargetHeartRateZoneDistributionView(
                distribution: .init(
                    totalDuration: .init(unit: .minute(), doubleValue: 0),
                    zone1: .init(unit: .minute(), doubleValue: 0),
                    zone2: .init(unit: .minute(), doubleValue: 0),
                    zone3: .init(unit: .minute(), doubleValue: 0),
                    zone4: .init(unit: .minute(), doubleValue: 0),
                    zone5: .init(unit: .minute(), doubleValue: 0)
                )
            )
            .cardContainer(fill: .background.secondary)
        }
        .padding()
    }
}
