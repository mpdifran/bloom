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
  let title: String
  let subtitle: String
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
