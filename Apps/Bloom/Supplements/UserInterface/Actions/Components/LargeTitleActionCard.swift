//
//  LargeTitleActionCard.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-17.
//

import SwiftUI

struct LargeTitleActionCard<Content>: View where Content: View {
  let title: String
  let contentBuilder: () -> Content

  init(
    _ title: String,
    @ViewBuilder contentBuilder: @escaping () -> Content
  ) {
    self.title = title
    self.contentBuilder = contentBuilder
  }

  var body: some View {
    VStack(spacing: 16) {
      Text(title)
        .font(.title)
        .fontDesign(.rounded)
        .bold()

      VStack {
        contentBuilder()
      }
      .padding(.top)
    }
  }
}

#Preview {
  PreviewSheetPresent {
    InsetCardView {
      LargeTitleActionCard("Actions") {
        Text("Hello World")
      }
    }
  }
}
