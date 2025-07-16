//
//  BloomPlusPackagesView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-14.
//

import SwiftUI
import RevenueCat
import StoreKit

struct BloomPlusPackagesView: View {
  let products: [Product]
  @Binding var selectedProductID: String

  @State private var selectedPackageToggle = false

  var body: some View {
    LazyVGrid(columns: [
      GridItem(.flexible()),
      GridItem(.flexible())
    ]) {
      ForEach(products, id: \.id) { product in
        BloomPlusPackageCard(
          title: product.sensibleName,
          subtitle: product.pricingString ?? "",
          introOffer: product.introductoryOfferString,
          isSelected: product.id == selectedProductID
        )
        .sensoryFeedback(.impact, trigger: selectedPackageToggle)
        .onTapGesture {
          selectedProductID = product.id
          selectedPackageToggle.toggle()
        }
      }
    }
  }
}
