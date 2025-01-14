//
//  BloomPlusFeaturesListView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI
import RevenueCat

struct BloomPlusFeaturesListView: View {

  var body: some View {
    HStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 0) {
        VStack(alignment: .leading, spacing: 20) {
          VStack(alignment: .leading) {
            Text("Bloom Plus")
              .font(.largeTitle)
              .bold()
              .fontDesign(.rounded)

            Text("Your personal health coach in your pocket.")
              .foregroundStyle(.secondary)
          }

          Label("Personalized goals tailored for you", systemImage: "star")
            .bold()

          Label("Lose weight in a sustainable way", systemImage: "gauge.open.with.lines.needle.33percent.and.arrowtriangle")
            .bold()

          Label("Quantify your health", systemImage: "bolt.heart")
            .bold()
        }
        .padding(.horizontal)
      }
      Spacer(minLength: 0)
    }
  }
}

#Preview {
  BloomPlusFeaturesListView()
}
