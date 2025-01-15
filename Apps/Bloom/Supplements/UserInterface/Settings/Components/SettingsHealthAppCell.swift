//
//  SettingsHealthAppCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-15.
//

import SwiftUI

struct SettingsHealthAppCell: View {
  let title: String

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
