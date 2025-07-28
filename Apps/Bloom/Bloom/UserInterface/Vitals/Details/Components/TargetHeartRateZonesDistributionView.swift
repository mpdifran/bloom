//
//  TargetHeartRateZonesDistributionView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-20.
//

import SwiftUI
import HealthKit
import CoreHealth

private extension CGFloat {
  static let spacing: CGFloat = 6
  static let barHeight: CGFloat = 30
}

struct TargetHeartRateZonesDistributionView: View {
  let distribution: WorkoutHeartRateReport.WorkoutHeartZoneDistribution
  let heartRateZones: HeartRateZones
  let displayGoal: Bool

  init(
    distribution: WorkoutHeartRateReport.WorkoutHeartZoneDistribution,
    heartRateZones: HeartRateZones,
    displayGoal: Bool = true
  ) {
    self.distribution = distribution
    self.heartRateZones = heartRateZones
    self.displayGoal = displayGoal
  }

  var body: some View {
    VStack(spacing: 16) {
      VStack(spacing: .spacing) {
        HeartRateZoneBar(
          title: "Zone 1",
          subtitle: heartRateZones.zone1RangeString,
          duration: distribution.zone1,
          totalDuration: distribution.totalDuration,
          maxProportion: distribution.maxPercent,
          multiplierString: "x \(Double.zone12Multiplier.format())"
        )
        .tint(.heartRateZone1)

        HeartRateZoneBar(
          title: "Zone 2",
          subtitle: heartRateZones.zone2RangeString,
          duration: distribution.zone2,
          totalDuration: distribution.totalDuration,
          maxProportion: distribution.maxPercent,
          multiplierString: "x \(Double.zone12Multiplier.format())"
        )
        .tint(.heartRateZone2)

        HeartRateZoneBar(
          title: "Zone 3",
          subtitle: heartRateZones.zone3RangeString,
          duration: distribution.zone3,
          totalDuration: distribution.totalDuration,
          maxProportion: distribution.maxPercent,
          multiplierString: "x \(Double.zone34Multiplier.format())"
        )
        .tint(.heartRateZone3)

        HeartRateZoneBar(
          title: "Zone 4",
          subtitle: heartRateZones.zone4RangeString,
          duration: distribution.zone4,
          totalDuration: distribution.totalDuration,
          maxProportion: distribution.maxPercent,
          multiplierString: "x \(Double.zone34Multiplier.format())"
        )
        .tint(.heartRateZone4)

        HeartRateZoneBar(
          title: "Zone 5",
          subtitle: heartRateZones.zone5RangeString,
          duration: distribution.zone5,
          totalDuration: distribution.totalDuration,
          maxProportion: distribution.maxPercent,
          multiplierString: "x \(Double.zone5Multiplier.format())"
        )
        .tint(.heartRateZone5)
      }

      Divider()

      HStack {
        Text("Total")
          .bold()
          .fontDesign(.rounded)

        Spacer()

        VStack(alignment: .trailing) {
          Text("\(distribution.scaledDurationSum.doubleValue(for: .minute()).format()) min")
            .font(.subheadline)
            .bold()
            .fontDesign(.rounded)
          if displayGoal {
            Text("/ \(Double.minZoneMinutes.format()) min")
              .foregroundStyle(.secondary)
              .font(.caption)
              .bold()
              .fontDesign(.rounded)
          }
        }
      }
    }
  }
}

struct HeartRateZoneBar: View {
  let title: String
  let subtitle: String
  let duration: HKQuantity
  let totalDuration: HKQuantity
  let maxProportion: Double
  let multiplierString: String

  var body: some View {
    HStack {
      GeometryReader { proxy in
        HStack {
          Image(systemSymbol: .heartFill)
            .fontWeight(.heavy)
            .fontDesign(.rounded)
            .font(.system(size: 12))

          VStack(alignment: .leading) {
            Text(title)
              .fontWeight(.heavy)
              .fontDesign(.rounded)
              .font(.system(size: 12))
            Text(subtitle)
              .font(.system(size: 8))
          }

          Spacer()

          Text(multiplierString)
            .font(.system(size: 12))
            .fontWeight(.heavy)
            .fontDesign(.rounded)
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 6)
        .frame(width: barWidth(proxy: proxy), height: .barHeight)
        .background {
          RoundedRectangle(cornerRadius: 12)
            .fill(.tint)
        }
      }
      .frame(height: .barHeight)

      Spacer()

      Text(formattedDuration)
        .fontWeight(.heavy)
        .font(.system(size: 12))
        .fontDesign(.rounded)
    }
  }

  func barWidth(proxy: GeometryProxy) -> CGFloat {
    let remainingWidth = proxy.size.width - 120
    let proportionalWidth = remainingWidth * barProportion

    return 120 + proportionalWidth
  }

  var barProportion: CGFloat {
    guard
      totalDuration.doubleValue(for: .second()) > 1,
      maxProportion > 0
    else { return 0 }


    let proportion = duration.doubleValue(for: .second()) / totalDuration.doubleValue(for: .second())
    return min(max(proportion / maxProportion, 0), 1)
  }

  var formattedDuration: String {
    return duration.doubleValue(for: .minute()).format() + " min"
  }

  func formattedTarget(target: Double) -> String {
    let dateComponents = DateComponents(minute: Int(target))
    return DateFormatter.timeIntervalHourMinuteShort.string(from: dateComponents) ?? ""
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      TargetHeartRateZonesDistributionView(
        distribution: WorkoutHeartRateReport.WorkoutHeartZoneDistribution(
          totalDuration: HKQuantity(unit: .minute(), doubleValue: 30),
          zone1: HKQuantity(unit: .minute(), doubleValue: 3),
          zone2: HKQuantity(unit: .minute(), doubleValue: 8),
          zone3: HKQuantity(unit: .minute(), doubleValue: 9),
          zone4: HKQuantity(unit: .minute(), doubleValue: 6),
          zone5: HKQuantity(unit: .minute(), doubleValue: 0)
        ),
        heartRateZones: HeartRateZones(
          heartRateReserve: 120,
          restingHeartRate: 60,
          maxHeartRate: 180,
          zone1: 130,
          zone2: 140,
          zone3: 150,
          zone4: 160,
          zone5: 170
        )
      )
      .cardContainer()
    }
  }
}
