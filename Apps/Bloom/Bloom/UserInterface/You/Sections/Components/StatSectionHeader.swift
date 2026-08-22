//
//  StatSectionHeader.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-30.
//

import SwiftUI
import SFSafeSymbols

struct StatSectionHeader: View {
  let symbol: SFSymbol
  /// LocalizedStringKey, not String: a String literal goes straight to Text with no catalog
  /// lookup, so every section header rendered in English regardless of language.
  let title: LocalizedStringKey
  let subtitle: LocalizedStringKey
  let isExpanded: Bool

  var body: some View {
    HStack {
      Image(systemSymbol: symbol)
        .font(.title)

      VStack(alignment: .leading) {
        Text(title)
          .font(.title2)
        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Image(systemSymbol: isExpanded ? .chevronUp : .chevronDown)
        .font(.title3)
        .foregroundStyle(.secondary)
    }
    .bold()
    .fontDesign(.rounded)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      StatSectionHeader(
        symbol: .moonZzzFill,
        title: "Sleep Quality",
        subtitle: "Last 7 Days",
        isExpanded: false
      )
    }
  }
}
