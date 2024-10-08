//
//  BloomPlusFeaturesListView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI

struct BloomPlusFeaturesListView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading) {
                    Text("Bloom Plus")
                        .font(.largeTitle)
                        .bold()

                    Text("Your personal health coach in your pocket.")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading) {
                    Text("$17 / Month")
                        .bold()
                        .font(.title)
                    Text("$199.99 a year")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Label("Personalized goals tailored for you", systemImage: "star")
                    .foregroundStyle(.secondary)

                Label("Lose weight in a sustainable way", systemImage: "gauge.open.with.lines.needle.33percent.and.arrowtriangle")
                    .foregroundStyle(.secondary)

                Label("Quantify your health", systemImage: "bolt.heart")
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    BloomPlusFeaturesListView()
}
