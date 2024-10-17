//
//  BloomPlusFeaturesListView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI

struct BloomPlusFeaturesListView: View {
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading) {
                    Text("Bloom Plus")
                        .font(.largeTitle)
                        .bold()

                    Text("Your personal health coach in your pocket.")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                TabView {
                    BloomPlusOfferView(
                        mainPrice: "$119.99",
                        mainPricePeriod: "/ Year",
                        subtitlePrice: "Try FREE for 3 Weeks"
                    )
                    .padding()

                    BloomPlusOfferView(
                        mainPrice: "$15.99",
                        mainPricePeriod: "/ Month",
                        subtitlePrice: ""
                    )
                    .padding()
                }
                .aspectRatio(1.2, contentMode: .fit)
                .tabViewStyle(.page)
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    BloomPlusFeaturesListView()
}
