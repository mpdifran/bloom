//
//  GaugeCard.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import SFSafeSymbols

struct GaugeCard: View {
  let title: String
  let value: String
  let progress: Double
  let symbol: SFSymbol
  let color: Color

  init(
    title: String,
    value: String,
    progress: Double,
    symbol: SFSymbol,
    color: Color
  ) {
    self.title = title
    self.value = value
    self.progress = progress
    self.symbol = symbol
    self.color = color
  }

  var body: some View {
    VStack(spacing: 8) {
      HStack(spacing: 6) {
        Image(systemSymbol: symbol)
          .font(.caption)
          .foregroundStyle(color)

        Text(title)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)

        Spacer()
      }

      Spacer()

      IconGauge(
        progress: progress,
        dimension: 70,
        lineThickness: 10,
        symbol: symbol,
        color: color
      )

      Text(value)
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .foregroundStyle(.primary)
    }
    .frame(maxWidth: .infinity)
    .aspectRatio(1, contentMode: .fit)
    .cardContainer()
  }
}

#Preview {
  LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
    GaugeCard(
      title: "Sleep Score",
      value: "85%",
      progress: 0.85,
      symbol: .moonZzzFill,
      color: .purple
    )

    GaugeCard(
      title: "VO2 Max",
      value: "Good",
      progress: 0.72,
      symbol: .lungs,
      color: .blue
    )

    GaugeCard(
      title: "Body Fat",
      value: "18%",
      progress: 0.65,
      symbol: .figureArmsOpen,
      color: .green
    )

    GaugeCard(
      title: "Zone Minutes",
      value: "420/600",
      progress: 0.7,
      symbol: .heartFill,
      color: .red
    )
  }
  .padding()
}
