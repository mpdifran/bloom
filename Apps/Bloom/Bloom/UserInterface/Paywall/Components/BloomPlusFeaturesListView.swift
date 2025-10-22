//
//  BloomPlusFeaturesListView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SFSafeSymbols
import SwiftUI
import RevenueCat
import BloomUI

struct BloomPlusFeaturesListView: View {

  var body: some View {
    VStack {
      HStack {
        FeatureCard(
          image: Image(systemSymbol: .bubbleLeftAndBubbleRightFill),
          message: "Ask Bud anything about your health"
        )

        FeatureCard(
          image: Image(systemSymbol: .heartFill),
          message: "Get health advice tailored to you"
        )
      }

      HStack {
        FeatureCard(
          image: Image(systemSymbol: .cameraFill),
          message: "Log nutrition with just a picture"
        )

        FeatureCard(
          image: Image(systemSymbol: .textViewfinder),
          message: "Describe your food to log it"
        )
      }

      HStack {
        FeatureCard(
          image: Image(systemSymbol: .checkmarkCircleFill),
          message: "Unlimited goals and reminders"
        )

        FeatureCard(
          image: Image(systemSymbol: .rectangle3GroupFill),
          message: "Daily insights that are actionable"
        )
      }
    }
    .padding(.horizontal)
  }
}

private struct FeatureCard: View {
  let image: Image
  let message: String

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      image
        .foregroundStyle(.tint)
        .bold()

      Spacer(minLength: 0)

      Text(message)
        .lineLimit(2)
        .minimumScaleFactor(0.3)
        .multilineTextAlignment(.leading)
        .font(.subheadline)
        .bold()
    }
    .horizontalAlignment(.leading)
    .aspectRatio(2, contentMode: .fit)
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      BloomPlusFeaturesListView()
    }
  }
}
