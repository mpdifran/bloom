//
//  ZoneDistributionStatCard.swift
//  Bloom
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI
import SFSafeSymbols

struct ZoneDistributionStatCard: View {
  let data: ZoneDistributionData?

  private var valueText: String {
    guard let data else { return String(localized: "No Data", comment: "Stat card value shown when there is no data") }
    return String(localized: "\(data.workoutCount) workouts", comment: "Zone distribution card value. The placeholder is a number of workouts.")
  }

  var body: some View {
    StatCard(
      symbol: .heartFill,
      title: "Zones",
      value: valueText,
      valueStyle: .largeTinted(String(localized: "Last 7 Days", comment: "Stat card subtitle: the value covers the last seven days"))
    ) {
      zoneBar
    }
    .tint(data == nil ? .gray : .heartRateZone3)
  }
}

private extension ZoneDistributionStatCard {

  @ViewBuilder
  var zoneBar: some View {
    if let data {
      GeometryReader { geometry in
        let total = data.zone1Percent + data.zone2Percent + data.zone3Percent + data.zone4Percent + data.zone5Percent
        let width = geometry.size.width

        HStack(spacing: 0) {
          if data.zone1Percent > 0 {
            Rectangle()
              .fill(Color.heartRateZone1)
              .frame(width: width * data.zone1Percent / total)
          }
          if data.zone2Percent > 0 {
            Rectangle()
              .fill(Color.heartRateZone2)
              .frame(width: width * data.zone2Percent / total)
          }
          if data.zone3Percent > 0 {
            Rectangle()
              .fill(Color.heartRateZone3)
              .frame(width: width * data.zone3Percent / total)
          }
          if data.zone4Percent > 0 {
            Rectangle()
              .fill(Color.heartRateZone4)
              .frame(width: width * data.zone4Percent / total)
          }
          if data.zone5Percent > 0 {
            Rectangle()
              .fill(Color.heartRateZone5)
              .frame(width: width * data.zone5Percent / total)
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
      }
      .frame(maxWidth: .infinity)
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        ZoneDistributionStatCard(data: previewZoneDistribution)
        ZoneDistributionStatCard(data: nil)
      }
      HStack {
        ZoneDistributionStatCard(data: previewZoneDistributionHighIntensity)
        ZoneDistributionStatCard(data: previewZoneDistributionSingleWorkout)
      }
    }
  }
}

private let previewZoneDistribution = ZoneDistributionData(
  zone1Percent: 0.1,
  zone2Percent: 0.25,
  zone3Percent: 0.35,
  zone4Percent: 0.2,
  zone5Percent: 0.1,
  workoutCount: 5
)

private let previewZoneDistributionHighIntensity = ZoneDistributionData(
  zone1Percent: 0.05,
  zone2Percent: 0.1,
  zone3Percent: 0.25,
  zone4Percent: 0.4,
  zone5Percent: 0.2,
  workoutCount: 3
)

private let previewZoneDistributionSingleWorkout = ZoneDistributionData(
  zone1Percent: 0.15,
  zone2Percent: 0.3,
  zone3Percent: 0.35,
  zone4Percent: 0.2,
  zone5Percent: 0,
  workoutCount: 1
)
