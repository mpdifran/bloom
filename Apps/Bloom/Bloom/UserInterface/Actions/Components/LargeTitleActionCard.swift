//
//  LargeTitleActionCard.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-17.
//

import SwiftUI

struct LargeTitleActionCard<Content>: View where Content: View {
  let title: String
  let includePadding: Bool
  let contentBuilder: () -> Content

  init(
    _ title: String,
    includePadding: Bool = true,
    @ViewBuilder contentBuilder: @escaping () -> Content
  ) {
    self.title = title
    self.includePadding = includePadding
    self.contentBuilder = contentBuilder
  }

  var body: some View {
    VStack(spacing: 16) {
      Text(title)
        .font(.title)
        .fontDesign(.rounded)
        .bold()
        .lineLimit(1)
        .minimumScaleFactor(0.3)

      VStack {
        contentBuilder()
      }
      .padding(.top)
    }
    .if(includePadding) {
      $0.padding()
    }
  }
}

#Preview {
  PreviewSheetPresent {
    CardView {
      LargeTitleActionCard("Actions") {
        Text("Hello World")
      }
    }
  }
}
