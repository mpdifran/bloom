//
//  BloomPlusPaywall.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI
import AppUI
import RevenueCat

struct BloomPlusPaywall: View {

  private let showDismiss: Bool

  init(showDismiss: Bool = true) {
    self.showDismiss = showDismiss
  }

  @State private var viewModel = ViewModel()
  @State private var selectedPackage: Package?
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
              .fill(.background)
          }
          .padding(.top, 170)
      }
      .scrollIndicators(.hidden)

      BloomPlusHeaderView(showDismiss: showDismiss)
        .padding(.horizontal)
        .zStackAlignment(.top)
    }
    .alert(error: $error)
    .shelf {
      purchaseShelf
    }
    .task {
      await viewModel.loadOfferings()
    }
    .presentationCompactAdaptation(.fullScreenCover)
    .animation(.default, value: selectedPackage)
    .onChange(of: entitlementController.hasBloomPro) { _, _ in
      guard entitlementController.hasBloomPro == true else { return }

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
      BloomPlusFeaturesListView()
      .padding(.top)
      .padding(.top)

      BloomPlusPackagesView(
        packages: viewModel.packages,
        selectedPackage: $selectedPackage
      )
      .padding()

      VStack(spacing: 30) {
        BloomPlusUserReviewListView()
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
      if let trialString = selectedPackage?.introductoryOfferTrialString {
        HStack {
          Image(systemName: "checkmark.seal.fill")
            .foregroundStyle(.white, .mutedGreen)
          Text(trialString.capitalized)
        }
        .font(.subheadline)
        .bold()
      }

      AsyncButton {
        guard let package = selectedPackage ?? viewModel.packages.first else { return }

        try await viewModel.purchase(package)
      } label: {
        if selectedPackage?.introductoryOfferTrialString != nil {
          Text("Start Free Trial")
        } else {
          Text("Invest in my Health")
        }
      }
      .buttonStyle(.paywall)
    }
  }
}

#Preview {
  BloomPlusPaywall()
}
