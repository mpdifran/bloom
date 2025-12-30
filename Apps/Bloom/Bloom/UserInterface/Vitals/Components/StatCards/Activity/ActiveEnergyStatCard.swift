//
//  ActiveEnergyStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-30.
//

import SwiftUI

struct ActiveEnergyStatCard: View {
  let activeEnergy: Double?

  var body: some View {
    StatCard(
      symbol: .flameFill,
      title: "Active Energy",
      value: formattedValue,
      valueStyle: .largeTinted("7 day avg")
    )
    .tint(activeEnergy == nil ? .gray : .mutedOrange)
  }
}

private extension ActiveEnergyStatCard {

  var formattedValue: String {
    guard let activeEnergy else { return "No Data" }
    return "\(Int(activeEnergy)) cal"
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        ActiveEnergyStatCard(activeEnergy: 450)
        ActiveEnergyStatCard(activeEnergy: nil)
      }
      HStack {
        ActiveEnergyStatCard(activeEnergy: 0)
        ActiveEnergyStatCard(activeEnergy: 1250)
      }
    }
  }
}
