//
//  BloomPlusUserReviewListView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI

struct BloomPlusUserReviewListView: View {
  var body: some View {
    VStack(spacing: 20) {
      Text("What Are People Saying?")
        .font(.title)
        .fontDesign(.rounded)
        .bold()
        .multilineTextAlignment(.center)

      BloomPlusUserTestimonialChatView(
        profilePhoto: .tori,
        testimonial: "I've improved my eating habits, and my energy levels are through the roof! Bloom has helped me prioritize my health.",
        name: "Tori M",
        position: .leading
      )
      .tint(.mutedPurple)

      BloomPlusUserTestimonialChatView(
        profilePhoto: .katie,
        testimonial: "I love how Bloom meets you where you are. The goals are always achievable, and I know I'm moving in the right direction.",
        name: "Katie M",
        position: .trailing
      )
      .tint(.mutedPurple)

      BloomPlusUserTestimonialChatView(
        profilePhoto: .kaitlyn,
        testimonial: "I've tried everything, but Bloom is something else! I've reached my weight goal with an approach that fits my lifestyle perfectly.",
        name: "Kaitlyn M",
        position: .leading
      )
      .tint(.mutedPurple)

//      BloomPlusUserTestimonialChatView(
//        profilePhoto: .katie,
//        testimonial: "Bloom has made me so much more healthy, thank you Team Bloom! ❤️",
//        name: "Clara A",
//        position: .trailing
//      )
//      .tint(.mutedPurple)
    }
    .horizontallyCentered()
  }
}

#Preview {
  BloomPlusUserReviewListView()
    .padding()
}
