//
//  SectionTitleView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-07.
//

import SwiftUI

struct SectionTitleView: View {
  let title: String
  let includeTopPadding: Bool

  init(
    _ title: String,
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
