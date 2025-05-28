//
//  ChatUnknownContentCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-02.
//

import SwiftUI

struct ChatUnknownContentCell: View {
  var body: some View {
    HStack {
      HStack {
        Image(systemSymbol: .exclamationmarkTriangleFill)
          .foregroundStyle(.white, .tint)
        Text("Unknown Content")
          .bold()
          .foregroundStyle(.tint)
        Spacer()
      }
      .cardContainer()
    }
    .padding(.horizontal)
    .tint(.mutedYellow)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ChatUnknownContentCell()
    }
  }
}
