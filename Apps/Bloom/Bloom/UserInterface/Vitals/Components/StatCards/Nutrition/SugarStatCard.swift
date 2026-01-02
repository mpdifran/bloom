//
//  SugarStatCard.swift
//  Bloom
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI
import SFSafeSymbols

struct SugarStatCard: View {
  let data: SugarChartData?

  private var valueText: String {
    guard let data else { return "No Data" }
    return "\(Int(data.averageGrams))g"
  }

  private var subtitle: String? {
    guard let data else { return nil }
    return data.isExceeded ? "Exceeded" : "Within Limit"
  }

  var body: some View {
    StatCard(
      symbol: .shippingbox,
      title: "Sugar",
      value: valueText,
      valueStyle: .largeTinted(subtitle)
    ) {
      barChart
    }
    .tint(data == nil ? .gray : .sugar)
  }
}

private extension SugarStatCard {

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
              .fill(Color.sugar)
              .frame(height: max(height, 2))
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
        SugarStatCard(data: previewSugarWithinLimit)
        SugarStatCard(data: previewSugarExceeded)
      }
      HStack {
        SugarStatCard(data: nil)
        SugarStatCard(data: previewSugarWithinLimit)
      }
    }
  }
}

private let previewSugarWithinLimit = SugarChartData(
  dailyValues: [20, 18, 22, 15, 24, 19, 21],
  averageGrams: 20,
  goal: 25
)

private let previewSugarExceeded = SugarChartData(
  dailyValues: [35, 40, 32, 45, 38, 42, 36],
  averageGrams: 38,
  goal: 25
)
