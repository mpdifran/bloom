//
//  RestingHeartRateStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-30.
//

import SwiftUI

struct RestingHeartRateStatCard: View {
  let restingHeartRate: Double?

  var body: some View {
    StatCard(
      symbol: .heartFill,
      title: "Resting HR",
      value: formattedValue,
      valueStyle: .largeTinted("7 day avg")
    )
    .tint(restingHeartRate == nil ? .gray : .mutedRed)
  }
}

private extension RestingHeartRateStatCard {

  var formattedValue: String {
    guard let restingHeartRate else { return "No Data" }
    return "\(Int(restingHeartRate)) bpm"
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        RestingHeartRateStatCard(restingHeartRate: 62)
        RestingHeartRateStatCard(restingHeartRate: nil)
      }
    }
  }
}
