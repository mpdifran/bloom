//
//  SettingsSectionContainer.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-26.
//

import SwiftUI

struct SettingsSectionContainer<Content>: View where Content: View {

  let contentBuilder: () -> Content

  init(@ViewBuilder contentBuilder: @escaping () -> Content) {
    self.contentBuilder = contentBuilder
  }

  var body: some View {
    VStack(spacing: 0) {
      contentBuilder()
    }
    .padding(.horizontal)
    .cardContainer(includePadding: false)
  }
}

#Preview {
  SettingsSectionContainer {
    Text("Hello World")
  }
}
