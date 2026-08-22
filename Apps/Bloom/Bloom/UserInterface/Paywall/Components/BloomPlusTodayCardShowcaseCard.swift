//
//  BloomPlusTodayCardShowcaseCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-09-17.
//

import SwiftUI
import BloomUI

struct BloomPlusTodayCardShowcaseCard<Content: View>: View {
  let title: LocalizedStringKey
  let message: LocalizedStringKey
  let contentBuilder: () -> Content

  init(
    title: LocalizedStringKey,
    message: LocalizedStringKey,
    @ViewBuilder contentBuilder: @escaping () -> Content
  ) {
    self.title = title
    self.message = message
    self.contentBuilder = contentBuilder
  }

  var body: some View {
    VStack {
      contentBuilder()
        .padding(.bottom)

      Text(title)
        .font(.headline)
        .bold()
        .fontDesign(.rounded)
        .fixedSize(horizontal: false, vertical: true)
        .horizontalAlignment(.leading)

      Text(message)
        .font(.headline)
        .foregroundStyle(.secondary)
        .fontDesign(.rounded)
        .horizontalAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 24)

      Spacer(minLength: 0)
    }
    .horizontallyCentered()
    .cardContainer(cornerRadius: 40)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      BloomPlusTodayCardShowcaseCard(
        title: "Title",
        message: "This is the message"
      ) {
        Text("Hello World")
          .cardContainer()
      }
    }
  }
}
