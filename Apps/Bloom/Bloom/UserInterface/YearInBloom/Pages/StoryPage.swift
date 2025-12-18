//
//  StoryPage.swift
//  Bloom
//
//  Created by Claude on 2025-12-18.
//

import SwiftUI

@MainActor
protocol StoryPage: View {
  associatedtype Content: View

  var focusSentence: Text { get }
  @ViewBuilder var mainContent: Content { get }
}

extension StoryPage {
  var body: some View {
    VStack(spacing: 0) {
      Spacer()
        .frame(height: 80)

      focusSentence
        .font(.title)
        .fontWeight(.bold)
        .fontDesign(.rounded)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)

      Spacer()
        .frame(height: 40)

      mainContent

      Spacer()
    }
  }
}
