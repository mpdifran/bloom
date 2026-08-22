//
//  SettingsHealthAppCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-15.
//

import SwiftUI

struct SettingsHealthAppCell: View {
  /// LocalizedStringKey, not String: a String literal is passed straight to Text without a
  /// catalog lookup, so the title rendered in English regardless of language.
  let title: LocalizedStringKey

  var body: some View {
    LabeledContent {
      HStack {
        Spacer()
        DisclosureIndicator()
          .bold()
      }
      .foregroundStyle(.secondary)
      .fixedSize()
    } label: {
      HStack {
        Image(.healthAppIcon)
          .resizable()
          .frame(square: 40)
        Text(title)
          .bold()
          .fontDesign(.rounded)
          .minimumScaleFactor(0.7)
          .lineLimit(2)
      }
    }
    .frame(height: 60)
    .selectable()
  }
}

#Preview {
  SettingsHealthAppCell(title: "Review Permissions")
}
