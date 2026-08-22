//
//  StatSection.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-30.
//

import SwiftUI
import SFSafeSymbols

struct StatSection<Content: View>: View {
  let symbol: SFSymbol
  /// LocalizedStringKey, not String: a String literal goes straight to Text with no catalog
  /// lookup, so every section header rendered in English regardless of language.
  let title: LocalizedStringKey
  let subtitle: LocalizedStringKey
  @ViewBuilder let content: () -> Content

  @State private var isExpanded = true

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      content()
        .fixedSize(horizontal: false, vertical: true)
    } label: {
      StatSectionHeader(
        symbol: symbol,
        title: title,
        subtitle: subtitle,
        isExpanded: isExpanded
      )
    }
    .disclosureGroupStyle(.statSection)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      StatSection(
        symbol: .moonZzzFill,
        title: "Sleep Quality",
        subtitle: "Last 7 Days"
      ) {
        Text("Content goes here")
          .padding()
      }
    }
  }
}
