//
//  Preview+Presented.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-23.
//

import SwiftUI

struct PreviewSheetPresent<Content>: View where Content: View {
  let content: () -> Content

  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }

  @State private var showSheet = true

  var body: some View {
    PreviewEnvironment {
      VStack {
        Spacer()

        Button {
          showSheet.toggle()
        } label: {
          Text("Show Sheet")
        }
        .buttonStyle(.primary)

        Spacer()
      }
      .horizontallyCentered()
      .sheet(isPresented: $showSheet) {
        content()
      }
    }
  }
}
