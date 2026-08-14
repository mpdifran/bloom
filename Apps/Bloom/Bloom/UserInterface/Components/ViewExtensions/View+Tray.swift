//
//  View+Tray.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-18.
//

import SwiftUI

struct ViewTray<TrayContent: View>: ViewModifier {
  private let spacing: CGFloat?
  private let trayContent: TrayContent

  init(
    spacing: CGFloat? = nil,
    @ViewBuilder trayContent: () -> TrayContent
  ) {
    self.spacing = spacing
    self.trayContent = trayContent()
  }

  func body(content: Content) -> some View {
    content
      .safeAreaInset(edge: .bottom) {
        VStack(spacing: spacing) {
          trayContent
        }
        .horizontallyCentered()
        .padding()
//        .background(.green, in: .rect(corner: .containerConcentric))
        .padding(3)
        .edgesIgnoringSafeArea(.bottom)
      }
  }
}

extension View {

  func tray<TrayContent: View>(
    spacing: CGFloat? = nil,
    @ViewBuilder _ trayContent: @escaping () -> TrayContent
  ) -> some View {
    modifier(
      ViewTray(spacing: spacing, trayContent: trayContent)
    )
  }
}



#Preview {
  ScrollView {
    List {
      Text(verbatim: "1")
      Text(verbatim: "2")
      Text(verbatim: "3")
      Text(verbatim: "4")
      Text(verbatim: "5")
      Text(verbatim: "6")
      Text(verbatim: "7")
      Text(verbatim: "8")
      Text(verbatim: "9")
      Text(verbatim: "0")
      Text(verbatim: "1")
      Text(verbatim: "2")
      Text(verbatim: "3")
      Text(verbatim: "4")
      Text(verbatim: "5")
      Text(verbatim: "6")
      Text(verbatim: "7")
      Text(verbatim: "8")
      Text(verbatim: "9")
      Text(verbatim: "0")
    }
  }
  .tray {
    Button {

    } label: {
      Text("Create")
        .horizontallyCentered()
    }
    .buttonStyle(.primary)

    Button {

    } label: {
      Text("Cancel")
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
  }
}
