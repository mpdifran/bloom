//
//  BigNumberCard.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import SFSafeSymbols

struct BigNumberCard: View {
  let title: String
  let value: String
  let unit: String?
  let symbol: SFSymbol
  let color: Color
  let trend: Trend?

  enum Trend {
    case up
    case down
    case neutral

    var symbol: SFSymbol {
      switch self {
      case .up: .arrowUp
      case .down: .arrowDown
      case .neutral: .minus
      }
    }

    var color: Color {
      switch self {
      case .up: .green
      case .down: .red
      case .neutral: .secondary
      }
    }
  }

  init(
    title: String,
    value: String,
    unit: String? = nil,
    symbol: SFSymbol,
    color: Color,
    trend: Trend? = nil
  ) {
    self.title = title
    self.value = value
    self.unit = unit
    self.symbol = symbol
    self.color = color
    self.trend = trend
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

      HStack(alignment: .firstTextBaseline, spacing: 2) {
        Text(value)
          .font(.system(size: 28, weight: .bold, design: .rounded))
          .foregroundStyle(.primary)
          .minimumScaleFactor(0.6)
          .lineLimit(1)

        if let unit {
          Text(unit)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
        }

        if let trend {
          Image(systemSymbol: trend.symbol)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(trend.color)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .aspectRatio(1, contentMode: .fit)
    .cardContainer(fill: .background)
  }
}

#Preview {
  LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
    BigNumberCard(
      title: "Resting HR",
      value: "62",
      unit: "bpm",
      symbol: .heartFill,
      color: .red,
      trend: .down
    )

    BigNumberCard(
      title: "VO2 Max",
      value: "42.5",
      unit: "ml/kg/min",
      symbol: .lungs,
      color: .blue
    )

    BigNumberCard(
      title: "Sleep Duration",
      value: "7h 23m",
      symbol: .moonZzzFill,
      color: .purple
    )

    BigNumberCard(
      title: "Active Energy",
      value: "423",
      unit: "cal",
      symbol: .flameFill,
      color: .orange,
      trend: .up
    )
  }
  .padding()
}
