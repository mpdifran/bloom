//
//  ChatContextCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-28.
//

import SwiftUI

struct ChatContextCell: View {
  let chatContext: ChatContext

  var body: some View {
    HStack {
      Spacer(minLength: 60)

      VStack(alignment: .leading, spacing: 0) {
        HStack {
          Image(systemSymbol: .quoteOpening)
          Text(chatContext.title)
          Spacer(minLength: 0)
        }
        .lineLimit(2)
        .font(.headline)
        .fontDesign(.rounded)
        .bold()
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background {
          Rectangle()
            .fill(.background.tertiary)
        }

        Text(chatContext.context)
          .font(.body)
          .fontDesign(.rounded)
          .fixedSize(horizontal: false, vertical: true)
          .padding()
      }
      .chatCardContainer(
        includePadding: false
      )
      .padding(.horizontal)
    }
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        ChatContextCell(
          chatContext: ChatContext(
            title: "Fiber Win",
            context: "You crushed your fiber goal with 11 g (110% of target), thanks to snacks like sourmelon bites. Fiber's your friend for digestion and fullness.",
            source: .todayInsight
          )
        )
      }
      .padding()
    }
  }
}
