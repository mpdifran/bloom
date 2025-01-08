//
//  BloomPlusFeaturesListView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI
import RevenueCat

struct BloomPlusFeaturesListView: View {
  let packages: [Package]
  @Binding var selectedPackage: Package?

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

        TabView(selection: $selectedPackage) {
          ForEach(packages) { package in
            BloomPlusOfferView(
              mainPrice: package.localizedPriceString,
              mainPricePeriod: package.storeProduct.subscriptionPeriod?.displayString ?? "",
              subtitlePrice: "Try FREE for 3 Weeks"
            )
            .padding(.horizontal)
            .padding(.bottom, 20)
            .tag(package)
          }
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
  @Previewable @State var selectedPackage: Package?

  BloomPlusFeaturesListView(
    packages: [.init(
      identifier: "preview",
      packageType: .monthly,
      storeProduct: .init(sk1Product: .init()),
      offeringIdentifier: "offering"
    )],
    selectedPackage: $selectedPackage
  )
}
