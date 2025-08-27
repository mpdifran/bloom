//
//  TodayViewSectionCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-27.
//

import SwiftUI

struct TodayViewSectionCell: View {
  let section: TodaySection

  @Binding var isEnabled: Bool

  var body: some View {
    HStack {
      Image(systemSymbol: .line3Horizontal)
        .font(.caption)
        .foregroundStyle(.tertiary)

      Image(systemSymbol: section.icon)
        .font(.body)
        .foregroundStyle(.secondary)
        .frame(width: 24)

      Text(section.displayName)
        .bold()
        .fontDesign(.rounded)

      Spacer()

      Toggle("", isOn: $isEnabled)
    }
    .cardContainer()
  }
}

#Preview {
  @Previewable @State var isEnabled = true

  PreviewEnvironment {
    BloomScrollView {
      TodayViewSectionCell(
        section: .goals,
        isEnabled: $isEnabled
      )
    }
  }
}
