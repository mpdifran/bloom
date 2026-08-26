//
//  WristTemperatureSummaryCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-08.
//

import SFSafeSymbols
import SwiftUI
import CoreHealth

struct WristTemperatureSummaryCell: View {
  let wristTemperature: SleepAnalysis.WristTemperatureDataPoint

  private var formattedDeviation: String {
    guard let baseline = wristTemperature.baselineWristTemperature else {
      // Fallback to absolute if no baseline
      let measurement = Measurement(value: wristTemperature.averageWristTemperature, unit: UnitTemperature.fahrenheit)
      let localized = measurement.localizedValue
      let unit = UnitTemperature(forLocale: .current).symbol
      return "\(localized.format(using: .oneDecimalPlace))\(unit)"
    }

    let currentMeasurement = Measurement(value: wristTemperature.averageWristTemperature, unit: UnitTemperature.fahrenheit)
    let baselineMeasurement = Measurement(value: baseline, unit: UnitTemperature.fahrenheit)
    let deviation = currentMeasurement.localizedValue - baselineMeasurement.localizedValue

    let sign = deviation >= 0 ? "+" : ""
    let unit = UnitTemperature(forLocale: .current).symbol
    return "\(sign)\(deviation.format(using: .oneDecimalPlace))\(unit)"
  }

  private var hasBaseline: Bool {
    wristTemperature.baselineWristTemperature != nil
  }

  var body: some View {
    VStack {
      SleepSectionTitleView(
        title: String(localized: "Wrist Temperature", comment: "Sleep detail section heading"),
        symbol: .thermometerMedium
      )

      HStack {
        Spacer()

        VStack(alignment: .trailing, spacing: 4) {
          Text(formattedDeviation)
            .font(.system(size: 60))
            .fontDesign(.rounded)
            .bold()
            .foregroundStyle(.tint)

          if hasBaseline {
            Text("vs Baseline")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .cardContainer()
    .tint(.mutedPurple)
  }
}

#Preview {
  WristTemperatureSummaryCell(
    wristTemperature: SleepAnalysis.WristTemperatureDataPoint.previewData
  )
}
