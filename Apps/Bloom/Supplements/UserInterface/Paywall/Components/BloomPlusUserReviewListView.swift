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
        testimonial: "I love using Bloom to keep track of my health. It's my new favourite app!",
        name: "Tori M",
        position: .leading
      )
      .tint(.mutedBlue.lighter(by: 0.2))

      BloomPlusUserTestimonialChatView(
        testimonial: "I lost 20 pounds in 2 months using Bloom, it's unbelievable!",
        name: "Katie M",
        position: .trailing
      )
      .tint(.mutedBlue)

      BloomPlusUserTestimonialChatView(
        testimonial: "This app has changed my life! I love it!",
        name: "Kaitlyn M",
        position: .leading
      )
      .tint(.mutedBlue.darker(by: 0.2))

      BloomPlusUserTestimonialChatView(
        testimonial: "Bloom has made me so much more healthy, thank you Team Bloom! ❤️",
        name: "Clara A",
        position: .trailing
      )
      .tint(.mutedBlue.darker(by: 0.4))
    }
    .horizontallyCentered()
  }
}

#Preview {
  BloomPlusUserReviewListView()
    .padding()
}
