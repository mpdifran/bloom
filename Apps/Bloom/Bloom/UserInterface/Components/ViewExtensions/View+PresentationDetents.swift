//
//  View+PresentationDetents.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-17.
//

import SwiftUI
import BloomUI

extension View {
  func presentationDetentSelfSizing() -> some View {
    modifier(SelfSizingPresentationDetentModifier())
  }
}

struct SelfSizingPresentationDetentModifier: ViewModifier {

  @State private var presentationDetent: PresentationDetent = .fraction(0.5)

  func body(content: Content) -> some View {
    content
      .readViewSize { proxy in
        updatePresentationDetents(geometry: proxy)
      }
      .presentationDetents([presentationDetent])
      .animation(.easeInOut, value: presentationDetent)
  }
}

private extension SelfSizingPresentationDetentModifier {

  func updatePresentationDetents(geometry: GeometryProxy) {
    presentationDetent = .height(geometry.size.height + geometry.safeAreaInsets.bottom + 16)
  }
}

#Preview {
  PreviewSheetPresent {
    ScrollView {
      VStack {
        Text(verbatim: "1")
        Text(verbatim: "2")
        Text(verbatim: "3")
        Text(verbatim: "4")
        Text(verbatim: "5")
        Text(verbatim: "6")
      }
      .horizontallyCentered()
      .cardContainer()
      .padding()
      .presentationDetentSelfSizing()
    }
    .groupedBackground()
  }
}
