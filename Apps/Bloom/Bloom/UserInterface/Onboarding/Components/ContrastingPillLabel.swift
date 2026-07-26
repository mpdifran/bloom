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
        Text(text)
          .padding(.vertical, 4)
          .padding(.horizontal, 12)
          .glassEffect()
    }
    .font(.caption)
    .bold()
    .fontDesign(.rounded)
  }
}

#Preview {
  @Previewable @State var stepCount = 1

  PreviewEnvironment {
    BloomScrollView {
      ContrastingPillLabel("Step \(stepCount) of 5")
        .contentTransition(.numericText())

      Button {
        stepCount += 1
      } label: {
        Text("Increment")
      }
      .buttonStyle(.primary)
    }
    .animation(.default, value: stepCount)
  }
}
