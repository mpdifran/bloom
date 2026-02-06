//
//  MiniHeartRateZoneDistributionView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-06.
//

import SwiftUI
import HealthKit
import CoreHealth

private extension CGFloat {
  static let spacing: CGFloat = 5
  static let barHeight: CGFloat = 5
}

struct MiniHeartRateZoneDistributionView: View {
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

private struct MiniHeartRateZoneBar: View {
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

    return min(max(CGFloat.barHeight, proportionWidth), proxy.size.width)
  }
}

#Preview {
  MiniHeartRateZoneDistributionView(
    distribution: WorkoutHeartRateReport.WorkoutHeartZoneDistribution(
      totalDuration: HKQuantity(unit: .minute(), doubleValue: 30),
      zone1: HKQuantity(unit: .minute(), doubleValue: 3),
      zone2: HKQuantity(unit: .minute(), doubleValue: 8),
      zone3: HKQuantity(unit: .minute(), doubleValue: 9),
      zone4: HKQuantity(unit: .minute(), doubleValue: 6),
      zone5: HKQuantity(unit: .minute(), doubleValue: 4)
    )
  )
  .padding()
}
