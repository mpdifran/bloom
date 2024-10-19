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
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading) {
                    Text("Bloom Plus")
                        .font(.largeTitle)
                        .bold()
                        .fontDesign(.rounded)

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
                    .padding(.horizontal)
                    .padding(.bottom, 20)

                    BloomPlusOfferView(
                        mainPrice: "$15.99",
                        mainPricePeriod: "/ Month",
                        subtitlePrice: ""
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .aspectRatio(1.3, contentMode: .fit)
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
