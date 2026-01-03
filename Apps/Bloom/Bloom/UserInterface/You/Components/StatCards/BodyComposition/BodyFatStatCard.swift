//
//  BodyFatStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-30.
//

import SwiftUI
import HealthKit

struct BodyFatStatCard: View {
  let bodyFatPercentage: HKQuantity?

  var body: some View {
    StatCard(
      symbol: .figureArmsOpen,
      title: "Body Fat",
      includePadding: false
    ) {
      gaugeContent
        .padding(.bottom, 8)
    }
    .tint(hasData ? .mutedBlue : .gray)
  }
}

private extension BodyFatStatCard {

  var gaugeContent: some View {
    if let bodyFatValue {
      StatGauge(
        progress: CGFloat(bodyFatValue / 100),
        label: "\(Int(bodyFatValue))%",
        color: .mutedBlue
      )
    } else {
      StatGauge(
        progress: 0,
        label: "--",
        color: .gray
      )
    }
  }

  var hasData: Bool {
    bodyFatPercentage != nil
  }

  var bodyFatValue: Double? {
    guard let bodyFatPercentage else { return nil }
    return bodyFatPercentage.doubleValue(for: .percent()) * 100
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        BodyFatStatCard(
          bodyFatPercentage: HKQuantity(unit: .percent(), doubleValue: 0.18)
        )

        BodyFatStatCard(bodyFatPercentage: nil)
      }

      HStack {
        BodyFatStatCard(
          bodyFatPercentage: HKQuantity(unit: .percent(), doubleValue: 0.25)
        )

        BodyFatStatCard(
          bodyFatPercentage: HKQuantity(unit: .percent(), doubleValue: 0.12)
        )
      }
    }
  }
}
