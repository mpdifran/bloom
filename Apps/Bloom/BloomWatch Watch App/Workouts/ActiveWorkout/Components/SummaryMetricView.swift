//
//  SummaryMetricView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-06.
//

import SwiftUI
import HealthKit
import CoreHealth

struct SummaryMetricView<Content: View>: View {
  let title: String
  let contentBuilder: () -> Content

  init(
    title: String,
    @ViewBuilder contentBuilder: @escaping () -> Content
  ) {
    self.title = title
    self.contentBuilder = contentBuilder
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text(title)
        .font(.system(.caption2, weight: .semibold))

      contentBuilder()
        .foregroundStyle(.tint)
    }
    .horizontalAlignment(.leading)
    .padding(8)
    .background {
      RoundedRectangle(cornerRadius: 12)
        .fill(.background.secondary)
    }
  }
}

extension SummaryMetricView where Content == Text {
  init(title: String, value: String) {
    self.title = title
    self.contentBuilder = {
      Text(value)
        .font(.system(.title2, design: .rounded, weight: .bold).lowercaseSmallCaps())
    }
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      VStack(alignment: .leading) {
        SummaryMetricView(
          title: "Total Time",
          value: "13m4s"
        )
        .tint(.mutedYellow)

        SummaryMetricView(
          title: "Total Energy",
          value: "354 Cal"
        )
        .tint(.mutedPink)

        SummaryMetricView(title: "Heart Rate Zones") {
          MiniHeartRateZoneDistributionView(
            distribution: WorkoutHeartRateReport.WorkoutHeartZoneDistribution(
              totalDuration: HKQuantity(unit: .second(), doubleValue: 3627),
              zone1: HKQuantity(unit: .second(), doubleValue: 82),
              zone2: HKQuantity(unit: .second(), doubleValue: 71),
              zone3: HKQuantity(unit: .second(), doubleValue: 63),
              zone4: HKQuantity(unit: .second(), doubleValue: 34),
              zone5: HKQuantity(unit: .second(), doubleValue: 26)
            )
          )
        }
        .tint(.white)
      }
    }
    .navigationTitle("Summary")
    .navigationBarTitleDisplayMode(.inline)
  }
}
