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
            question: "Why do you charge for Bloom?",
            answer: "We charge for Bloom in order to make sure you always have the best health recommendations. We're always improving the app and making sure your health is our top priority. We also have operational costs to keep the app running."
          )
          BloomPlusFAQCell(
            question: "How is my data secured?",
            answer: "Privacy is one of our core values. Your health data never leaves your device, so there's no risk of it getting leaked to a bad actor. We explicitly don't track food you search for, and your food logs only exist on your device."
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
    BloomPlusFAQView()
    .padding()
    .groupedBackground()
}
