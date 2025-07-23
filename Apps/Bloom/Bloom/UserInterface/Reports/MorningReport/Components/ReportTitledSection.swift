//
//  ReportTitledSection.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-23.
//

import SwiftUI

struct ReportTitledSection<Content: View>: View {
  let title: String
  let includeExtraTitlePadding: Bool
  let content: () -> Content

  init(
    _ title: String,
    includeExtraTitlePadding: Bool = false,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.title = title
    self.includeExtraTitlePadding = includeExtraTitlePadding
    self.content = content
  }

  var body: some View {
    VStack {
      SectionTitleView(title)
        .padding(.horizontal)
        .if(includeExtraTitlePadding) {
          $0.padding(.horizontal)
        }

      content()
    }
  }
}

#Preview {
  PreviewEnvironment {
    ReportTitledSection("Section Title") {
      Text("Hello World")
        .horizontallyCentered()
        .cardContainer()
    }
  }
}
