//
//  FiberStatCard.swift
//  Bloom
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI
import SFSafeSymbols

struct FiberStatCard: View {
  let data: FiberChartData?

  private var valueText: String {
    guard let data else { return String(localized: "No Data", comment: "Stat card value shown when there is no data") }
    return "\(Int(data.averageGrams))g"
  }

  private var subtitle: String? {
    guard let data else { return nil }
    return data.isSufficient
      ? String(localized: "Sufficient", comment: "Fiber card subtitle when intake meets the goal")
      : String(localized: "Insufficient", comment: "Fiber card subtitle when intake is below the goal")
  }

  var body: some View {
    StatCard(
      symbol: .leafFill,
      title: "Fiber",
      value: valueText,
      valueStyle: .largeTinted(subtitle)
    ) {
      barChart
    }
    .tint(data == nil ? .gray : .fiber)
  }
}

private extension FiberStatCard {

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
              .fill(Color.fiber)
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
        FiberStatCard(data: previewFiberSufficient)
        FiberStatCard(data: previewFiberInsufficient)
      }
      HStack {
        FiberStatCard(data: nil)
        FiberStatCard(data: previewFiberSufficient)
      }
    }
  }
}

private let previewFiberSufficient = FiberChartData(
  dailyValues: [28, 25, 30, 22, 27, 31, 26],
  averageGrams: 27,
  goal: 25
)

private let previewFiberInsufficient = FiberChartData(
  dailyValues: [15, 12, 18, 10, 14, 16, 11],
  averageGrams: 14,
  goal: 25
)
