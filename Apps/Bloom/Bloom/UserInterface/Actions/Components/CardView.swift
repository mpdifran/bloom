//
//  CardView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-23.
//

import SwiftUI

struct CardView<Content>: View where Content: View {
  let cornerRadius: CGFloat
  let contentBuilder: () -> Content

  init(
    cornerRadius: CGFloat = 60,
    @ViewBuilder contentBuilder: @escaping () -> Content
  ) {
    self.cornerRadius = cornerRadius
    self.contentBuilder = contentBuilder
  }

  var body: some View {
      VStack {
        contentBuilder()
      }
      .horizontallyCentered()
      .presentationDetentSelfSizing()
      .presentationCornerRadius(cornerRadius)
      .presentationDragIndicator(.visible)
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      CardView {
        VStack {
          Text("Hello")
          Text("World")
        }
        .padding()
      }
    }
  }
}
