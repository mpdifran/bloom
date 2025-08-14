//
//  BloomPlusTryBloomHeaderView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-10.
//

import SwiftUI

struct BloomPlusTryBloomHeaderView: View {

  let canTryForFree: Bool

  var body: some View {
    VStack(spacing: 30) {
      VStack(spacing: 10) {
        bloomPlusLogo

        Text(canTryForFree ? "Try Bloom for Free" : "Try Bloom")
          .font(.largeTitle)
          .bold()
          .fontDesign(.rounded)

        Text("No more one-size-fits-all advice. Bloom reads your health data and turns it into clear, actionable tips you’ll actually use.")
          .foregroundStyle(.secondary)
      }
      .multilineTextAlignment(.center)
    }
  }
}

extension BloomPlusTryBloomHeaderView {

  var bloomPlusLogo: some View {
    HStack(spacing: 0) {
      Text("Bloom")
        .padding(4)
      Text("Plus")
        .fontDesign(.monospaced)
        .foregroundStyle(.white)
        .padding(4)
        .background {
          RoundedRectangle(cornerRadius: 6)
            .fill(.tint)
        }
    }
    .bold()
    .font(.caption)
    .background {
      RoundedRectangle(cornerRadius: 6)
        .fill(.regularMaterial)
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      BloomPlusTryBloomHeaderView(canTryForFree: true)
    }
  }
}
