//
//  EditableChatImageView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-09.
//

import SwiftUI

struct EditableChatImageView: View {
  let image: UIImage
  let onRemove: () -> Void

  var body: some View {
    Image(uiImage: image)
      .resizable()
      .scaledToFill()
      .frame(square: 50)
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .overlay {
        Button {
          onRemove()
        } label: {
          Image(systemSymbol: .xmarkCircleFill)
            .foregroundStyle(.white, .background.tertiary)
            .frame(square: 30)
        }
        .offset(x: 10, y: -10)
        .zStackAlignment(.topTrailing)
      }
  }
}

#Preview {
  EditableChatImageView(image: UIImage(named: "CrackersAndCheese")!) {

  }
}
