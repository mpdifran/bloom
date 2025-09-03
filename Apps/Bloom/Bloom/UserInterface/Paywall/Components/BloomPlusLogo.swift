//
//  BloomPlusLogo.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-09-03.
//

import SwiftUI

struct BloomPlusLogo: View {
  var body: some View {
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
    BloomPlusLogo()
  }
}
