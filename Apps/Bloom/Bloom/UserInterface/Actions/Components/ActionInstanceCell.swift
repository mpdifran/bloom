//
//  ActionInstanceCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-17.
//

import SwiftUI

struct ActionInstanceCell: View {
  let image: ImageResource
  let title: String

  var body: some View {
    HStack(spacing: 16) {
      Image(image)
        .foregroundStyle(.tint)

      Text(title)
        .font(.title3)
        .bold()
        .fontDesign(.rounded)

      Spacer()

      DisclosureIndicator()
    }
    .cardContainer()
  }
}

#Preview {
  ScrollView {
    VStack {
      ActionInstanceCell(image: .todayTab, title: "Weight")
        .tint(.mutedPurple)
    }
    .padding()
  }
  .groupedBackground()
}
