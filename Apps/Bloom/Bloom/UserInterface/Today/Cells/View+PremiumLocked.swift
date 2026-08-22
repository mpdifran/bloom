//
//  View+PremiumLocked.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-09-03.
//

import SwiftUI

extension View {

  /// LocalizedStringKey, not String: a String literal is passed straight to Text without a
  /// catalog lookup, so the lock overlay rendered in English regardless of language.
  func premiumLocked(_ title: LocalizedStringKey) -> some View {
    self
      .blur(radius: 7)
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
