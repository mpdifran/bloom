//
//  EditableChatContextCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-28.
//

import SwiftUI
import SFSafeSymbols

struct EditableChatContextCell: View {
  let chatContext: ChatContext
  let onRemove: () -> Void

  var body: some View {
    HStack {
      Image(systemSymbol: .quoteOpening)
      Text(chatContext.title)
        .fontWeight(.heavy)
        .lineLimit(2)
        .multilineTextAlignment(.leading)
    }
    .font(.caption)
    .frame(height: 50)
    .padding(.horizontal)
    .frame(minWidth: 0, maxWidth: 120)
    .background {
      RoundedRectangle(cornerRadius: 10)
        .fill(.background)
    }
    .overlay {
      Button {
        onRemove()
      } label: {
        Image(systemSymbol: .xmarkCircleFill)
          .foregroundStyle(.tint, .background.tertiary)
          .frame(square: 30)
      }
      .offset(x: 10, y: -10)
      .zStackAlignment(.topTrailing)
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      EditableChatContextCell(
        chatContext: ChatContext(
          title: "Fiber Win",
          context: "You crushed your fiber goal with 11 g (110% of target), thanks to snacks like sourmelon bites. Fiber's your friend for digestion and fullness."
        )
      ) {

      }
    }
  }
}
