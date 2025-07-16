//
//  BloomPlusPackagePlanPicker.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-20.
//

import SwiftUI
import RevenueCat
import StoreKit
import TelemetryDeck

struct BloomPlusPackagePlanPicker: View {
  let products: [Product]
  @Binding var selectedProductID: String

  @State private var showOfferCodeSheet = false
  @State private var selectedPackageToggle = false
  @State private var presentedSheet: AnyView?
  @State private var error: Error?

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    LargeTitleActionCard("Select a Plan") {
      VStack(spacing: 20) {
        ForEach(products, id: \.id) { product in
          BloomPlusPackageCell(
            title: product.sensibleName,
            cost: product.pricingString ?? "",
            costMonthly: product.monthlyPriceString,
            offer: product.introductoryOfferString,
            isSelected: product.id == selectedProductID
          )
          .sensoryFeedback(.impact, trigger: selectedPackageToggle)
          .onTapGesture {
            selectedProductID = product.id
            selectedPackageToggle.toggle()
            dismiss()
          }
        }

        HStack {
          Spacer(minLength: 0)

          Button("Promo Code") {
            showOfferCodeSheet.toggle()
          }
          .offerCodeRedemption(isPresented: $showOfferCodeSheet) { result in
              switch result {
              case .failure(let error):
                  TelemetryDeck.errorOccurred(
                      id: "PreferencesView.offerCodeRedemption",
                      category: .thrownException,
                      message: error.localizedDescription
                  )
                  self.error = error
              default:
                  break
              }
          }

          Text("•")

          Button("Restore Purchases") {
            ThrowingUserTask(error: $error) {
              try await restorePurchases()
            }
          }

          Spacer(minLength: 0)
        }
      }
    }
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(30)
    .presentationDetentSelfSizing()
    .alert(error: $error)
  }
}

private extension BloomPlusPackagePlanPicker {

  func restorePurchases() async throws {
    try await PackageStore.shared.restore()
  }
}

//#Preview {
//  @Previewable @State var selectedPackage: Package?
//
//  PreviewSheetPresent {
//    BloomPlusPackagePlanPicker(
//      packages: [
//        Package(
//          identifier: "preview",
//          packageType: .monthly,
//          storeProduct: StoreProduct(sk1Product: SK1Product()),
//          offeringIdentifier: "offering",
//          webCheckoutUrl: nil
//        )
//      ],
//      selectedPackage: $selectedPackage
//    )
//  }
//}
