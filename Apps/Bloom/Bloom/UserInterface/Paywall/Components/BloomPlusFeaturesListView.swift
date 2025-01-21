//
//  BloomPlusFeaturesListView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI
import RevenueCat

struct BloomPlusFeaturesListView: View {

  let canTryForFree: Bool

  var body: some View {
    VStack(spacing: 30) {
      VStack(spacing: 10) {
        bloomPlusLogo

        Text(canTryForFree ? "Try Bloom for Free" : "Try Bloom")
          .font(.largeTitle)
          .bold()
          .fontDesign(.rounded)

        Text("Your personal health coach in your pocket.")
          .foregroundStyle(.secondary)
      }

      VStack {
        HStack {
          FeatureCard(
            image: Image(systemName: "star"),
            message: "Personalized goals tailored to you"
          )

          FeatureCard(
            image: Image(systemName: "gauge.open.with.lines.needle.33percent.and.arrowtriangle"),
            message: "Get to your ideal body weight"
          )
        }

        HStack {
          FeatureCard(
            image: Image(systemName: "camera"),
            message: "Log nutrition with just a picture"
          )

          FeatureCard(
            image: Image(systemName: "barcode.viewfinder"),
            message: "Scan food barcodes with ease"
          )
        }

        HStack {
          FeatureCard(
            image: Image(systemName: "figure.run"),
            message: "Keep track of your workouts"
          )

          FeatureCard(
            image: Image(systemName: "heart"),
            message: "Comprehensive view of your health"
          )
        }
      }
    }
    .padding(.horizontal)
    .tint(.mutedPurple)
  }
}

private extension BloomPlusFeaturesListView {

  var bloomPlusLogo: some View {
    HStack(spacing: 0) {
      Text("Bloom")
        .padding(4)
      Text("Plus")
        .fontDesign(.monospaced)
        .foregroundStyle(.white)
        .padding(4)
        .background {
          RoundedRectangle(cornerRadius: 6)
            .fill(.tint)
        }
    }
    .bold()
    .font(.caption)
    .background {
      RoundedRectangle(cornerRadius: 6)
        .fill(.regularMaterial)
    }
  }
}

private struct FeatureCard: View {
  let image: Image
  let message: String

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      image
        .foregroundStyle(.tint)
        .bold()

      Text(message)
        .lineLimit(2)
        .minimumScaleFactor(0.3)
        .multilineTextAlignment(.leading)
        .font(.subheadline)
        .bold()
    }
    .horizontalAlignment(.leading)
    .cardContainer()
  }
}

#Preview {
  VStack {
    BloomPlusFeaturesListView(canTryForFree: true)
  }
  .groupedBackground()
}
