//
//  BloomPlusTryBloomHeaderView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-10.
//

import SwiftUI
import BloomUI

struct BloomPlusTryBloomHeaderView: View {

  let canTryForFree: Bool

  var body: some View {
    VStack(spacing: 10) {
      Text(canTryForFree ? "Prioritize Your Health. On The House." : "Smarter Health Starts Today")
        .font(.largeTitle)
        .bold()
        .fontDesign(.rounded)
        .horizontalAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)

      Text("No generic plans. No one-size-fits-all tips. Just real insights based on your real data.")
        .foregroundStyle(.secondary)
        .horizontalAlignment(.leading)
    }
    .multilineTextAlignment(.leading)
    .horizontalAlignment(.leading)
    .fixedSize(horizontal: false, vertical: true)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      BloomPlusTryBloomHeaderView(canTryForFree: true)
    }
  }
}
