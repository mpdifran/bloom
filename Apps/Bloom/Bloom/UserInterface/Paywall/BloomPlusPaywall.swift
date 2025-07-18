//
//  BloomPlusPaywall.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI
import AppUI
import RevenueCat
import StoreKit
import TelemetryDeck

struct BloomPlusPaywall: View {

  private let showDismiss: Bool
  private let onPurchase: () -> Void

  init(
    showDismiss: Bool = true,
    onPurchase: @escaping () -> Void = { }
  ) {
    self.showDismiss = showDismiss
    self.onPurchase = onPurchase

    self.selectedProductID = .ProductIdentifier.yearly
  }

  @State private var viewModel = ViewModel()
  @State private var selectedProductID: String
  @State private var presentedSheet: AnyView?
  @State private var error: Error?

  @ObservedObject private var packageStore = PackageStore.shared

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ZStack {
      BloomPlusPaywallHeroImageView()
        .zStackAlignment(.top)
        .clipped()
        .ignoresSafeArea(edges: .top)

      ScrollView(.vertical) {
        contentView
          .background {
            RoundedRectangle(cornerRadius: 30)
              .fill(.paywallBackground)
          }
          .padding(.top, 170)
      }
      .scrollIndicators(.hidden)

      BloomPlusHeaderView(showDismiss: showDismiss)
        .padding(.horizontal)
        .zStackAlignment(.top)
    }
    .tintedBackground(tint: .paywallBackground)
    .alert(error: $error)
    .shelf {
      purchaseShelf
    }
    .sheet($presentedSheet)
    .onAppear {
      TelemetryDeck.signal("View Paywall")
    }
    .task {
      await viewModel.loadOfferings()
    }
    .presentationCompactAdaptation(.fullScreenCover)
    .animation(.default, value: selectedProductID)
    .onChange(of: packageStore.hasBloomPro) { _, _ in
      guard packageStore.hasBloomPro == true else { return }

      TelemetryDeck.signal("Paywall Purchase Complete")
      dismiss()
      onPurchase()
    }
    .onChange(of: viewModel.products) { _, _ in
      if viewModel.products.contains(where: { $0.id == .ProductIdentifier.yearly }) {
        selectedProductID = .ProductIdentifier.yearly
      } else {
        selectedProductID = viewModel.products.first?.id ?? .ProductIdentifier.yearly
      }
    }
  }
}

private extension BloomPlusPaywall {

  var selectedProduct: Product? {
    viewModel.products.first(where: { $0.id == selectedProductID })
  }

  var contentView: some View {
    VStack {
      VStack(spacing: 30) {
        BloomPlusTryBloomHeaderView(canTryForFree: selectedProduct?.hasFreeIntroductoryOffer == true)
          .padding(.top)
          .padding(.top)
          .horizontallyCentered()
          .padding(.horizontal)
        BloomPlusFeaturesListView()
      }

      VStack(spacing: 30) {
        BloomPlusUserReviewListView()
        BloomPlusFAQView()
        BloomPlusLegalSectionView(restorePurchases: {
          ThrowingUserTask(error: $error) {
            try await viewModel.restorePurchases()
          }
        })
      }
      .padding()
    }
  }

  var purchaseShelf: some View {
    VStack {
      AsyncButton {
        guard let product = selectedProduct ?? viewModel.products.first else { return }

        try await viewModel.purchase(product)
      } label: {
        Group {
          if let title = selectedProduct?.introductoryPurchaseButtonTitle {
            Text(title)
          } else {
            Text("Invest in my Health")
          }
        }
        .horizontallyCentered()
      }
      .buttonStyle(.primary)

      Group {
        if let eventualCostString = selectedProduct?.introductoryEventualCostDescription {
          Text(eventualCostString)
        } else if let pricingString = selectedProduct?.pricingString {
          Text(pricingString)
        }
      }
      .font(.subheadline)
      .bold()

      Button("View All Plans") {
        presentedSheet = BloomPlusPackagePlanPicker(
          products: viewModel.products,
          selectedProductID: $selectedProductID
        ).asAny
      }
      .bold()
      .frame(minHeight: 50)
      .foregroundStyle(.tint)
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomPlusPaywall()
  }
}
