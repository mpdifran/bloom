//
//  View+PremiumLocked.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-09-03.
//

import SwiftUI

extension View {

  func premiumLocked(_ title: String) -> some View {
    self
      .blur(radius: 5)
      .overlay {
        VStack {
          Image(systemSymbol: .lockFill)
          Text(title)
        }
        .fontDesign(.rounded)
        .bold()
      }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      TodayCardCell(
        symbol: .sunrise,
        title: "Today's Advice",
        content: "Don't do anything stupid.",
        color: .mutedOrange
      )
      .premiumLocked("Unlock Insights")
    }
  }
}
