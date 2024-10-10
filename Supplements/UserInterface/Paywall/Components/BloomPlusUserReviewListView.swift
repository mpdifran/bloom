//
//  BloomPlusUserReviewListView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI

struct BloomPlusUserReviewListView: View {
    var body: some View {
        VStack {
            Text("What Are People Saying?")
                .font(.title)
                .fontDesign(.rounded)
                .bold()
                .multilineTextAlignment(.center)

            BloomPlusUserTestimonialChatView(
                testimonial: "I love using Bloom to keep track of my health. It's my new favourite app!",
                position: .leading
            )
            .tint(.mutedBlue)

            BloomPlusUserTestimonialChatView(
                testimonial: "I lost 20 pounds in 2 months using Bloom, it's unbelievable!",
                position: .trailing
            )
            .tint(.mutedIndigo)

            BloomPlusUserTestimonialChatView(
                testimonial: "I love using Bloom to keep track of my health. It's my new favourite app!",
                position: .leading
            )
            .tint(.mutedPurple)

            BloomPlusUserTestimonialChatView(
                testimonial: "I lost 20 pounds in 2 months using Bloom, it's unbelievable!",
                position: .trailing
            )
            .tint(.mutedPink)
        }
    }
}

#Preview {
    BloomPlusUserReviewListView()
}
