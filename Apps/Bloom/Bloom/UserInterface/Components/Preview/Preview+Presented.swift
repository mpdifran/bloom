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
  @State private var developerSettings = false

  var body: some View {
    VStack {
      Button {
        showSheet.toggle()
      } label: {
        Text("Show Sheet")
      }
      .buttonStyle(.primary)

      Button {
        developerSettings.toggle()
      } label: {
        Text("Developer Settings")
      }
    }
    .sheet(isPresented: $showSheet) {
      content()
    }
    .sheet(isPresented: $developerSettings) {
      DeveloperSettingsView()
    }
  }
}
