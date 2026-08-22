//
//  SectionTitleView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-07.
//

import SwiftUI

struct SectionTitleView: View {
  /// LocalizedStringKey, not String: a String literal is passed straight to Text without a
  /// catalog lookup, so every section title rendered in English regardless of language.
  let title: LocalizedStringKey
  let includeTopPadding: Bool

  init(
    _ title: LocalizedStringKey,
    includeTopPadding: Bool = true
  ) {
    self.title = title
    self.includeTopPadding = includeTopPadding
  }

  var body: some View {
    Text(title)
      .font(.subheadline)
      .foregroundStyle(.secondary)
      .bold()
      .zStackAlignment(.leading)
      .padding(includeTopPadding ? .top : [])
  }
}

#Preview {
  SectionTitleView("Focus Areas")
}
