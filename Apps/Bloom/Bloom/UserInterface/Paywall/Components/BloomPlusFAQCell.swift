//
//  BloomPlusFAQCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-21.
//

import SwiftUI

struct BloomPlusFAQCell: View {
  let question: String
  let answer: String

  @State private var isExpanded: Bool = false

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(question)
          .multilineTextAlignment(.leading)
          .fixedSize(horizontal: false, vertical: true)
        Spacer()
        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
      }
      .bold()

      if isExpanded {
        Divider()
        Text(answer)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.leading)
          .fixedSize(horizontal: false, vertical: true)
          .transition(.opacity)
      }
    }
    .cardContainer()
    .animation(.easeInOut, value: isExpanded)
    .sensoryFeedback(.selection, trigger: isExpanded)
    .font(.subheadline)
    .onTapGesture {
      isExpanded.toggle()
    }
  }
}

#Preview {
  ScrollView {
    VStack {
      BloomPlusFAQCell(
        question: "Why do I have to start a free trial?",
        answer: "It's just the best app."
      )
    }
    .padding()
  }
  .groupedBackground()
}
