//
//  BloomPlusOfferView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-17.
//

import SwiftUI

struct BloomPlusOfferView: View {
    let mainPrice: String
    let mainPricePeriod: String
    let subtitlePrice: String

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(mainPrice)
                            .bold()
                            .font(.largeTitle)
                            .fontDesign(.rounded)

                        Text(mainPricePeriod)
                            .font(.headline)
                            .fontDesign(.rounded)
                            .bold()
                            .foregroundStyle(.secondary)
                    }
                    Text(subtitlePrice)
                        .font(.headline)
                        .fontDesign(.rounded)
                        .bold()
                }

                Label("Personalized goals tailored for you", systemImage: "star")

                Label("Lose weight in a sustainable way", systemImage: "gauge.open.with.lines.needle.33percent.and.arrowtriangle")

                Label("Quantify your health", systemImage: "bolt.heart")
            }
            Spacer(minLength: 0)
        }
        .cardContainer(fill: .background.secondary, stroke: .tint)
    }
}

#Preview {
    BloomPlusOfferView(
        mainPrice: "$119.99",
        mainPricePeriod: "per Year",
        subtitlePrice: "$9.99 / Month"
    )
}
