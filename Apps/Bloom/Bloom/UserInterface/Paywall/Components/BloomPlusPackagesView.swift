//
//  BloomPlusPackagesView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-14.
//

import SwiftUI
import RevenueCat

struct BloomPlusPackagesView: View {
  let packages: [Package]
  @Binding var selectedPackage: Package?

  @State private var selectedPackageToggle = false

  var body: some View {
    LazyVGrid(columns: [
      GridItem(.flexible()),
      GridItem(.flexible())
    ]) {
      ForEach(packages) { package in
        BloomPlusPackageCard(
          title: package.sensibleName,
          subtitle: package.pricingString ?? "",
          introOffer: package.introductoryOfferString,
          isSelected: package == selectedPackage
        )
        .sensoryFeedback(.impact, trigger: selectedPackageToggle)
        .onTapGesture {
          selectedPackage = package
          selectedPackageToggle.toggle()
        }
      }
    }
  }
}

#Preview {
  @Previewable @State var selectedPackage: Package?

  BloomPlusPackagesView(
    packages: [
      Package(
        identifier: "preview",
        packageType: .monthly,
        storeProduct: StoreProduct(sk1Product: SK1Product()),
        offeringIdentifier: "offering"
      )
    ],
    selectedPackage: $selectedPackage
  )
}
