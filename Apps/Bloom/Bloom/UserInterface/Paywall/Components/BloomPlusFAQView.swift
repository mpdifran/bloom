//
//  BloomPlusFAQView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-21.
//

import SwiftUI

struct BloomPlusFAQView: View {
  var body: some View {
    VStack(spacing: 20) {
      Text("Frequently Asked Questions")
        .font(.title)
        .fontDesign(.rounded)
        .bold()
        .multilineTextAlignment(.center)

      VStack {
        BloomPlusFAQCell(
          question: "Do I need an Apple Watch to use this app?",
          answer: "While we recommend using some sort of wearable device (Apple Watch, Fitbit, Oura, etc) to get the most out of the app, it is not necessary. You can use a lot of features without having a watch!"
        )
        BloomPlusFAQCell(
          question: "Can I track food in this app?",
          answer: "Yes! You can use Bloom to scan labels and barcodes, or even take photos of your meals."
        )
        BloomPlusFAQCell(
          question: "How is my personal data secured?",
          answer: "Privacy is one of our core values. Your personal data is only stored on your device, and Bud reads specific data temporarily depending on what you ask. Your chat history is never used for AI training, and can only be accessed by you. We explicitly don't track food you search for, and your food logs only exist on your device."
        )
        BloomPlusFAQCell(
          question: "How can I cancel my trial?",
          answer: "If you need to cancel your trial, you can cancel it right from the app's settings (we made it easy to find!). You can also manage your subscriptions on your Apple Account."
        )
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      BloomPlusFAQView()
    }
  }
}
