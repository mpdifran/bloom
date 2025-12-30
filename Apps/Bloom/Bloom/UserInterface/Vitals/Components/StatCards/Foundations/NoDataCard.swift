//
//  NoDataCard.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import SFSafeSymbols

struct NoDataCard: View {
  let title: String
  let symbol: SFSymbol

  init(
    title: String,
    symbol: SFSymbol
  ) {
    self.title = title
    self.symbol = symbol
  }

  var body: some View {
    VStack(spacing: 12) {
      Spacer()

      Image(systemSymbol: symbol)
        .font(.title2)
        .foregroundStyle(.tertiary)

      Text(title)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)

      Text("No Data")
        .font(.caption2)
        .foregroundStyle(.tertiary)

      Spacer()
    }
    .frame(maxWidth: .infinity)
    .aspectRatio(1, contentMode: .fit)
    .cardContainer(fill: .background)
  }
}

#Preview {
  LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
    NoDataCard(
      title: "Resting HR",
      symbol: .heartFill
    )

    NoDataCard(
      title: "Blood Pressure",
      symbol: .waveformPathEcg
    )
  }
  .padding()
}
