//
//  CardView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-23.
//

import SwiftUI

struct CardView<Content>: View where Content: View {

  let contentBuilder: () -> Content

  init(
    @ViewBuilder contentBuilder: @escaping () -> Content
  ) {
    self.contentBuilder = contentBuilder
  }

  var body: some View {
    VStack {
      contentBuilder()
    }
    .horizontallyCentered()
    .presentationDetentSelfSizing()
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
    .presentationBackground(.background.secondary)
  }
}

#Preview {
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
