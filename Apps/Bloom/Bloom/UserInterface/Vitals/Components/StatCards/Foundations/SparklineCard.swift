//
//  SparklineCard.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import SFSafeSymbols
import Charts

struct SparklineCard: View {
  let title: String
  let value: String
  let data: [Double]
  let symbol: SFSymbol
  let color: Color

  init(
    title: String,
    value: String,
    data: [Double],
    symbol: SFSymbol,
    color: Color
  ) {
    self.title = title
    self.value = value
    self.data = data
    self.symbol = symbol
    self.color = color
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        Image(systemSymbol: symbol)
          .font(.caption)
          .foregroundStyle(color)

        Text(title)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
      }

      Spacer()

      if data.isNotEmpty {
        Chart {
          ForEach(Array(data.enumerated()), id: \.offset) { index, value in
            LineMark(
              x: .value("Day", index),
              y: .value("Value", value)
            )
            .interpolationMethod(.catmullRom)

            AreaMark(
              x: .value("Day", index),
              y: .value("Value", value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
              LinearGradient(
                colors: [color.opacity(0.3), color.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
              )
            )
          }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .foregroundStyle(color)
        .frame(height: 40)
      }

      Text(value)
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .foregroundStyle(.primary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .aspectRatio(1, contentMode: .fit)
    .cardContainer(fill: .background)
  }
}

#Preview {
  LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
    SparklineCard(
      title: "Bedtime",
      value: "Consistent",
      data: [22.5, 23.0, 22.75, 23.25, 22.5, 23.0, 22.75],
      symbol: .bedDoubleFill,
      color: .purple
    )

    SparklineCard(
      title: "Weight Trend",
      value: "-2.3 lbs",
      data: [185, 184.5, 184.2, 183.8, 183.5, 183.2, 182.7],
      symbol: .scalemass,
      color: .blue
    )
  }
  .padding()
}
