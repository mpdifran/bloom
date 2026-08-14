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
  let packages: [Package]
  @Binding var selectedPackage: Package?

  @State private var showOfferCodeSheet = false
  @State private var selectedPackageToggle = false
  @State private var presentedSheet: AnyView?
  @State private var error: Error?

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    LargeTitleActionCard("Select a Plan") {
      VStack(spacing: 20) {
        ForEach(packages) { package in
          BloomPlusPackageCell(
            title: package.sensibleName,
            cost: package.pricingString ?? "",
            costMonthly: package.monthlyPriceString,
            offer: package.introductoryOfferString,
            isSelected: package == selectedPackage
          )
          .sensoryFeedback(.impact, trigger: selectedPackageToggle)
          .onTapGesture {
            selectedPackage = package
            selectedPackageToggle.toggle()
            dismiss()
          }
        }

        HStack {
          Spacer(minLength: 0)

          Button {
            showOfferCodeSheet.toggle()
          } label: {
            Label("Promo Code", systemSymbol: .tag)
          }
          .offerCodeRedemption(isPresented: $showOfferCodeSheet) { result in
            switch result {
            case .failure(let error):
              TelemetryDeck.errorOccurred(
                id: "BloomPlusPackagePlanPicker.offerCodeRedemption",
                category: .thrownException,
                message: error.localizedDescription
              )
              self.error = error
            default:
              break
            }
          }

          Text(verbatim: "•")
            .foregroundStyle(.tint)

          Button("Restore Purchases") {
            ThrowingUserTask(error: $error) {
              try await restorePurchases()
            }
          }

          Spacer(minLength: 0)
        }
        .bold()
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
    _ = try await Purchases.shared.restorePurchases()
  }
}

#Preview {
  @Previewable @State var selectedPackage: Package?

  PreviewSheetPresent {
    BloomPlusPackagePlanPicker(
      packages: [
        Package(
          identifier: "preview",
          packageType: .monthly,
          storeProduct: StoreProduct(sk1Product: SK1Product()),
          offeringIdentifier: "offering",
          webCheckoutUrl: nil
        )
      ],
      selectedPackage: $selectedPackage
    )
  }
}
