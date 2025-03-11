//
//  BloomPlusPaywall.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI
import AppUI
import RevenueCat
import TelemetryDeck

struct BloomPlusPaywall: View {

  private let showDismiss: Bool

  init(showDismiss: Bool = true) {
    self.showDismiss = showDismiss
  }

  @State private var viewModel = ViewModel()
  @State private var selectedPackage: Package?
  @State private var presentedSheet: AnyView?
  @State private var error: Error?

  @State private var entitlementController = EntitlementController.shared

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ZStack {
      BloomPlusPaywallHeroImageView()
        .zStackAlignment(.top)
        .clipped()
        .ignoresSafeArea(edges: .top)

      ScrollView {
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
      TelemetryDeck.signal("OB Paywall")
    }
    .task {
      await viewModel.loadOfferings()
    }
    .presentationCompactAdaptation(.fullScreenCover)
    .animation(.default, value: selectedPackage)
    .onChange(of: entitlementController.hasBloomPro) { _, _ in
      guard entitlementController.hasBloomPro == true else { return }

      TelemetryDeck.signal("OB Purchase Complete")
      dismiss()
    }
    .onChange(of: viewModel.packages) { _, _ in
      selectedPackage = viewModel.packages.first
    }
  }
}

private extension BloomPlusPaywall {

  var contentView: some View {
    VStack {
      VStack(spacing: 30) {
        BloomPlusTryBloomHeaderView(canTryForFree: selectedPackage?.hasFreeIntroductoryOffer == true)
          .tint(.mutedPurple)
          .padding(.top)
          .padding(.top)
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
        guard let package = selectedPackage ?? viewModel.packages.first else { return }

        try await viewModel.purchase(package)
      } label: {
        if let title = selectedPackage?.introductoryPurchaseButtonTitle {
          Text(title)
        } else {
          Text("Invest in my Health")
        }
      }
      .buttonStyle(.paywall)
      .tint(.white)

      Group {
        if let eventualCostString = selectedPackage?.introductoryEventualCostDescription {
          Text(eventualCostString)
        } else if let pricingString = selectedPackage?.pricingString {
          Text(pricingString)
        }
      }
      .font(.subheadline)
      .bold()

      Button("View All Plans") {
        presentedSheet = BloomPlusPackagePlanPicker(
          packages: viewModel.packages,
          selectedPackage: $selectedPackage
        ).asAny
      }
      .bold()
      .frame(minHeight: 50)
      .foregroundStyle(.tint)
    }
  }
}

#Preview {
  BloomPlusPaywall()
}
