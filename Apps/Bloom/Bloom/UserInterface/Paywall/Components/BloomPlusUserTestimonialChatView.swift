//
//  BloomPlusUserTestimonialChatView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI

struct BloomPlusUserTestimonialChatView: View {
  let profilePhoto: ImageResource
  let testimonial: String
  let name: String
  let position: ChatBubblePosition

  var body: some View {
    HStack(alignment: .bottom, spacing: 0) {
      if position == .leading {
        profilePic
      } else {
        Spacer(minLength: 0)
      }

      ChatBubble(
        position: position,
        showTail: true,
        shouldFill: true,
        includePadding: false,
        foregroundStyle: .white,
        backgroundStyle: .tint
      ) {
        Text(testimonial)
      }

      if position == .trailing {
        profilePic
      } else {
        Spacer(minLength: 0)
      }
    }
  }
}

private extension BloomPlusUserTestimonialChatView {

  var profilePic: some View {
    VStack {
      Image(profilePhoto)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(square: 60)
        .clipShape(Circle())
//        .overlay {
//          Circle()
//            .stroke(.fill)
//        }
      Text(name)
        .font(.caption)
        .bold()
    }
  }
}

#Preview {
  BloomPlusUserTestimonialChatView(
    profilePhoto: .kaitlyn,
    testimonial: "I love using Bloom to keep track of my health. It's my new favourite app!",
    name: "Tori",
    position: .leading
  )
  BloomPlusUserTestimonialChatView(
    profilePhoto: .kaitlyn,
    testimonial: "I love using Bloom to keep track of my health.",
    name: "Katie",
    position: .trailing
  )
}
