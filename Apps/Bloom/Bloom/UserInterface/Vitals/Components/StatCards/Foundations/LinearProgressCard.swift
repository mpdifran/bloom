//
//  LinearProgressCard.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import SFSafeSymbols

struct LinearProgressCard: View {
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

      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          Capsule()
            .fill(color.opacity(0.2))
            .frame(height: 8)

          Capsule()
            .fill(color)
            .frame(width: geometry.size.width * min(progress, 1.0), height: 8)
        }
      }
      .frame(height: 8)

      HStack {
        Text(value)
          .font(.system(size: 16, weight: .semibold, design: .rounded))
          .foregroundStyle(.primary)

        Spacer()

        Text("\(Int(progress * 100))%")
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .aspectRatio(1, contentMode: .fit)
    .cardContainer(fill: .background)
  }
}

#Preview {
  LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
    LinearProgressCard(
      title: "Fiber",
      value: "18g / 25g",
      progress: 0.72,
      symbol: .leafFill,
      color: .green
    )

    LinearProgressCard(
      title: "Deep Sleep",
      value: "45 min",
      progress: 0.6,
      symbol: .moonZzzFill,
      color: .indigo
    )
  }
  .padding()
}
