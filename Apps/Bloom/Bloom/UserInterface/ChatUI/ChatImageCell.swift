//
//  ChatImageCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-09.
//

import SwiftUI

struct ChatImageCell: View {
  let image: UIImage
  let isCurrentUser: Bool

  var body: some View {
    HStack {
      if isCurrentUser {
        Spacer()
      }

      Image(uiImage: image)
        .resizable()
        .scaledToFill()
        .frame(square: 200)
        .clipShape(RoundedRectangle(cornerRadius: 17))

      if !isCurrentUser {
        Spacer()
      }
    }
    .padding(.horizontal)
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        ChatImageCell(image: UIImage(named: "CrackersAndCheese")!, isCurrentUser: true)
        ChatImageCell(image: UIImage(named: "CrackersAndCheese")!, isCurrentUser: false)
      }
    }
    .groupedBackground()
  }
}
