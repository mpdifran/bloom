//
//  BloomPlusUserTestimonialChatView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI

struct BloomPlusUserTestimonialChatView: View {
    let testimonial: String
    let name: String
    let position: ChatBubblePosition

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if position == .leading {
                profilePic
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
            }
        }
        .padding()
    }
}

private extension BloomPlusUserTestimonialChatView {

    var profilePic: some View {
        VStack {
            Circle()
                .fill(.green)
                .frame(square: 60)
            Text(name)
                .font(.caption)
                .bold()
        }
    }
}

#Preview {
    BloomPlusUserTestimonialChatView(
        testimonial: "I love using Bloom to keep track of my health. It's my new favourite app!",
        name: "Tori",
        position: .leading
    )
    BloomPlusUserTestimonialChatView(
        testimonial: "I love using Bloom to keep track of my health.",
        name: "Katie",
        position: .trailing
    )
}
