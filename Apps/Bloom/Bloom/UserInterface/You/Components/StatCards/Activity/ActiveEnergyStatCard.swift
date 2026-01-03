//
//  ActiveEnergyStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-30.
//

import SwiftUI

struct ActiveEnergyStatCard: View {
  let data: ActiveEnergyChartData?

  var body: some View {
    if let data {
      StatCard(
        symbol: .flameFill,
        title: "Active Energy",
        value: formattedValue,
        valueStyle: .largeTinted("7 day avg")
      ) {
        barChart
      }
      .tint(.mutedOrange)
    } else {
      StatCard(
        symbol: .flameFill,
        title: "Active Energy",
        value: "No Data",
        valueStyle: .largeTinted(nil)
      )
      .tint(.gray)
    }
  }
}

private extension ActiveEnergyStatCard {

  var formattedValue: String {
    guard let data else { return "No Data" }
    return "\(Int(data.average)) cal"
  }

  @ViewBuilder
  var barChart: some View {
    if let data, data.dailyValues.isNotEmpty {
      let maxValue = data.dailyValues.max() ?? 1

      GeometryReader { geometry in
        HStack(alignment: .bottom, spacing: 2) {
          ForEach(0..<7, id: \.self) { index in
            let value = data.dailyValues[safe: index] ?? 0
            let height = maxValue > 0 ? (value / maxValue) * geometry.size.height : 0

            RoundedRectangle(cornerRadius: 2)
              .fill(Color.mutedOrange)
              .frame(height: max(height, value > 0 ? 4 : 2))
              .opacity(value > 0 ? 1 : 0.3)
          }
        }
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        ActiveEnergyStatCard(data: ActiveEnergyChartData(
          dailyValues: [450, 380, 520, 400, 350, 480, 420],
          average: 428
        ))
        ActiveEnergyStatCard(data: nil)
      }
      HStack {
        ActiveEnergyStatCard(data: ActiveEnergyChartData(
          dailyValues: [0, 0, 520, 400, 0, 480, 420],
          average: 455
        ))
        ActiveEnergyStatCard(data: ActiveEnergyChartData(
          dailyValues: [1250, 980, 1100, 1300, 1150, 1050, 1200],
          average: 1147
        ))
      }
    }
  }
}
