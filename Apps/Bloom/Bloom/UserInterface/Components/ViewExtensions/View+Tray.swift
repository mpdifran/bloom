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
        .background {
          RoundedRectangle(cornerRadius: 60)
            .fill(.green)
            .padding(3)
            .edgesIgnoringSafeArea(.bottom)
        }
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
      Text("1")
      Text("2")
      Text("3")
      Text("4")
      Text("5")
      Text("6")
      Text("7")
      Text("8")
      Text("9")
      Text("0")
      Text("1")
      Text("2")
      Text("3")
      Text("4")
      Text("5")
      Text("6")
      Text("7")
      Text("8")
      Text("9")
      Text("0")
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
