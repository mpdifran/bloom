//
//  SleepWristTempStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-29.
//

import SwiftUI
import BloomFoundation

struct SleepWristTempStatCard: View {
  let data: WristTempData?

  var body: some View {
    StatCard(
      symbol: .thermometerMedium,
      title: "Wrist Temp",
      value: formattedDeviation,
      valueStyle: .largeTinted(String(localized: "Last Night vs Baseline", comment: "Stat card subtitle comparing last night to the baseline"))
    )
    .tint(data == nil ? AnyShapeStyle(.gray) : AnyShapeStyle(.mutedPurple))
  }
}

private extension SleepWristTempStatCard {

  var deviation: Double? {
    guard let data else { return nil }

    // Convert each temperature to locale unit, then calculate difference
    let avgMeasurement = Measurement(value: data.weeklyAverage, unit: UnitTemperature.fahrenheit)
    let latestMeasurement = Measurement(value: data.latestTemp, unit: UnitTemperature.fahrenheit)

    let localizedAvg = avgMeasurement.localizedValue
    let localizedLatest = latestMeasurement.localizedValue
    return localizedLatest - localizedAvg
  }

  var formattedDeviation: String {
    guard let deviation else { return String(localized: "No Data", comment: "Stat card value shown when there is no data") }

    let sign = deviation >= 0 ? "+" : "-"
    let formatted = abs(deviation).format(using: .oneDecimalPlace)
    let unit = UnitTemperature(forLocale: .current).symbol
    return "\(sign)\(formatted)\(unit)"
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        SleepWristTempStatCard(data: WristTempData(weeklyAverage: 97.5, latestTemp: 97.8))
        SleepWristTempStatCard(data: WristTempData(weeklyAverage: 97.5, latestTemp: 97.3))
      }
      HStack {
        SleepWristTempStatCard(data: nil)
        SleepWristTempStatCard(data: WristTempData(weeklyAverage: 97.5, latestTemp: 97.5))
      }
    }
  }
}
