//
//  View+PresentationDetents.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-17.
//

import SwiftUI

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
  }
}

private extension SelfSizingPresentationDetentModifier {

  func updatePresentationDetents(geometry: GeometryProxy) {
    presentationDetent = .height(geometry.size.height + geometry.safeAreaInsets.bottom + 16)
  }
}

#Preview {
  struct PreviewView: View {

      @State private var showSheet = true

      var body: some View {
          Button {
              showSheet.toggle()
          } label: {
              Text("Show Sheet")
          }
          .sheet(isPresented: $showSheet) {
            ScrollView {
              VStack {
                Text("1")
                Text("2")
                Text("3")
                Text("4")
                Text("5")
                Text("6")
              }
              .cardContainer()
              .padding()
            }
            .groupedBackground()
          }
      }
  }
  return PreviewView()
}
