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
    Button {
      showSheet.toggle()
    } label: {
      Text("Show Sheet")
    }
    .sheet(isPresented: $showSheet) {
      content()
    }
  }
}
