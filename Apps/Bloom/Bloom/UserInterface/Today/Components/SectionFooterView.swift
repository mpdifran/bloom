//
//  SectionFooterView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-28.
//

import SwiftUI

struct SectionFooterView: View {
  let footer: String

  init(_ footer: String) {
    self.footer = footer
  }

  var body: some View {
    Text(footer)
      .font(.caption)
      .foregroundStyle(.secondary)
      .bold()
      .horizontalAlignment(.leading)
      .multilineTextAlignment(.leading)
      .padding(.horizontal)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      SectionTitleView("Title")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("Content", showDisclosureIndicator: true) {
        }
      }

      SectionFooterView("This is some footer content")
    }
  }
}
