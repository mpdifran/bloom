//
//  ContrastingPillLabel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-19.
//

import SwiftUI

struct ContrastingPillLabel: View {
  let text: String

  init(_ text: String) {
    self.text = text
  }

  var body: some View {
    Group {
      if #available(iOS 26.0, *) {
        Text(text)
          .padding(.vertical, 4)
          .padding(.horizontal, 12)
          .glassEffect()
      } else {
        Text(text)
          .padding(.vertical, 4)
          .padding(.horizontal, 12)
          .background {
            Capsule()
              .fill(.ultraThickMaterial)
          }
      }
    }
    .font(.caption)
    .bold()
    .fontDesign(.rounded)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ContrastingPillLabel("Step 1 of 5")
    }
  }
}
