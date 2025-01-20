//
//  InsetCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-17.
//

import SwiftUI
import AppUI

private extension CGFloat {
  static let cardInset: CGFloat = 12
}

/// A self sizing card view that is inset from the edges of the screen.
struct InsetCardView<Content, S>: View where Content: View, S: ShapeStyle {

  let includePadding: Bool
  let background: S
  let contentBuilder: () -> Content

  init(
    includePadding: Bool = true,
    background: S = BackgroundStyle.background.secondary,
    @ViewBuilder contentBuilder: @escaping () -> Content
  ) {
    self.includePadding = includePadding
    self.background = background
    self.contentBuilder = contentBuilder
  }

  var body: some View {
    VStack {
      contentBuilder()
    }
    .frame(minHeight: 60)
    .cardContainer(
      fill: background,
      includePadding: includePadding,
      cornerRadius: 30
    )
    .horizontallyCentered()
    .presentationDetentSelfSizing()
    .padding(.horizontal, .cardInset)
    .presentationBackground(.clear)
    .presentationCornerRadius(0)
    .presentationDragIndicator(.visible)
    .zStackAlignment(.top)
    .ignoresSafeArea()
  }
}

#Preview {
  PreviewSheetPresent {
    InsetCardView {
      Text("Hello World")
      ProminentButton("Save") { }
        .tint(.mutedBlue)
    }
  }
}
