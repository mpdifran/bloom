//
//  StatusIndicatorCard.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import SFSafeSymbols

struct StatusIndicatorCard: View {
  let title: String
  let status: String
  let level: Level
  let symbol: SFSymbol

  enum Level: Int, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
    case optimal = 3

    var color: Color {
      switch self {
      case .low: .red
      case .medium: .orange
      case .high: .yellow
      case .optimal: .green
      }
    }
  }

  init(
    title: String,
    status: String,
    level: Level,
    symbol: SFSymbol
  ) {
    self.title = title
    self.status = status
    self.level = level
    self.symbol = symbol
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        Image(systemSymbol: symbol)
          .font(.caption)
          .foregroundStyle(level.color)

        Text(title)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
      }

      Spacer()

      HStack(spacing: 4) {
        ForEach(Level.allCases, id: \.rawValue) { levelCase in
          Capsule()
            .fill(levelCase.rawValue <= level.rawValue ? level.color : Color.secondary.opacity(0.2))
            .frame(height: 6)
        }
      }

      Text(status)
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
    StatusIndicatorCard(
      title: "Activity Level",
      status: "Moderate",
      level: .medium,
      symbol: .figureTennis
    )

    StatusIndicatorCard(
      title: "Regularity",
      status: "Regular",
      level: .optimal,
      symbol: .clockFill
    )

    StatusIndicatorCard(
      title: "Net Energy",
      status: "Deficit",
      level: .high,
      symbol: .flameFill
    )

    StatusIndicatorCard(
      title: "Stress",
      status: "High",
      level: .low,
      symbol: .boltFill
    )
  }
  .padding()
}
