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
        profilePhoto: .katie,
        testimonial: "I love how I can just ask Bud anything about my health, and I get instant advice based on my data. This is like magic!",
        name: "Katie W",
        position: .leading
      )

      BloomPlusUserTestimonialChatView(
        profilePhoto: .mark,
        testimonial: "It's so convenient tracking food just by taking a picture of it!",
        name: "Mark F",
        position: .trailing
      )

      BloomPlusUserTestimonialChatView(
        profilePhoto: .kaitlyn,
        testimonial: "Bud is good at creating targeted workouts that align with my fitness goals.",
        name: "Kaitlyn R",
        position: .leading
      )

      BloomPlusUserTestimonialChatView(
        profilePhoto: .tori,
        testimonial: "Bud is so good at helping me decide what to eat every day to stay healthy.",
        name: "Tori E",
        position: .trailing
      )
    }
    .horizontallyCentered()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      BloomPlusUserReviewListView()
    }
  }
}
