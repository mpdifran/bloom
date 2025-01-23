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
    DisclosureGroup(isExpanded: $isExpanded) {
      Text(answer)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .transition(.opacity)
    } label: {
      Text(question)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }
    .disclosureGroupStyle(BloomPlusFAQDisclosureGroupStyle())
    .sensoryFeedback(.selection, trigger: isExpanded)
    .font(.subheadline)
    .onTapGesture {
      withAnimation(.easeInOut) {
        isExpanded.toggle()
      }
    }
  }
}

private struct BloomPlusFAQDisclosureGroupStyle: DisclosureGroupStyle {
  func makeBody(configuration: Configuration) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        configuration.label
        Spacer()
        Image(systemName: "chevron.down")
          .foregroundStyle(.secondary)
          .rotationEffect(.degrees(configuration.isExpanded ? -180 : 0))
      }
      .bold()
      
      if configuration.isExpanded {
        Divider()
        configuration.content
      }
    }
    .clipped()
    .cardContainer()
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
