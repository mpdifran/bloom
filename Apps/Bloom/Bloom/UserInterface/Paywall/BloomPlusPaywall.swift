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

extension BloomPlusPaywall {
  enum Focus {
    case standard
    case todayInsights
    case biologicalAge
  }
}

struct BloomPlusPaywall: View {

  private let focus: Focus
  private let showDismiss: Bool
  private let onPurchase: () -> Void
  private let onDismiss: () -> Void

  /// Creates a Bloom Plus paywall view.
  ///
  /// - Parameters:
  ///   - focus: The feature to emphasize in the paywall. Defaults to `.standard`.
  ///   - showDismiss: Whether to show the X dismiss button. Defaults to `true`.
  ///   - onPurchase: Called after a successful purchase completes, after the view dismisses.
  ///                 Use for purchase-specific tracking or actions. Defaults to empty closure.
  ///   - onDismiss: Called when the paywall dismisses for ANY reason (purchase, X button, swipe).
  ///                Dismissal order: `dismiss()` → `onPurchase()` (if purchase) → `onDismiss()`.
  ///                Use this to continue your flow after the paywall closes. Defaults to empty closure.
  init(
    focus: Focus = .standard,
    showDismiss: Bool = true,
    onPurchase: @escaping () -> Void = { },
    onDismiss: @escaping () -> Void = { }
  ) {
    self.focus = focus
    self.showDismiss = showDismiss
    self.onPurchase = onPurchase
    self.onDismiss = onDismiss
  }

  @State private var viewModel = ViewModel()
  @State private var selectedPackage: Package?
  @State private var presentedSheet: AnyView?
  @State private var showOfferCodeSheet = false
  @State private var error: Error?

  @ObservedObject private var entitlementController = EntitlementController.shared

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ZStack {
      ScrollView(.vertical) {
        BloomPlusPaywallHeroImageView()
          .parallaxOverscroll()

        Group {
          switch focus {
          case .standard:
            standardContent
          case .todayInsights:
            todayInsightFocusedContent
          case .biologicalAge:
            biologicalAgeFocusedContent
          }
        }
        .background {
          RoundedRectangle(cornerRadius: 30)
            .fill(.paywallBackground)
        }
        .padding(.top, -30)
      }
      .ignoresSafeArea(edges: .top)

      BloomPlusHeaderView(showDismiss: showDismiss, onDismiss: onDismiss)
        .padding(.horizontal)
        .zStackAlignment(.top)
    }
    .tintedBackground(tint: .paywallBackground)
    .alert(error: $error)
    .shelf(includePadding: false) {
      purchaseShelf
    }
    .sheet($presentedSheet)
    .onAppear {
      TelemetryDeck.signal("View Paywall")
    }
    .task {
      await viewModel.loadOfferings()
    }
    .task {
      // Track any paywall appearance for periodic paywall timer
      await PeriodicPaywallManager.shared.updateLastShownDate()
    }
    .presentationCompactAdaptation(.fullScreenCover)
    .animation(.default, value: selectedPackage)
    .onChange(of: entitlementController.hasBloomPro) { _, _ in
      guard entitlementController.hasBloomPro == true else { return }

      TelemetryDeck.signal("Paywall Purchase Complete")
      TelemetryDeck.signal("AB: Periodic Paywall v3 - Success")

      dismiss()
      onPurchase()
      onDismiss()
    }
    .onChange(of: viewModel.packages) { _, _ in
      if let package = viewModel.packages.first(where: { $0.hasFreeIntroductoryOffer }) {
        selectedPackage = package
      } else {
        selectedPackage = viewModel.packages.first
      }
    }
  }
}

private extension BloomPlusPaywall {

  var standardContent: some View {
    VStack {
      VStack(spacing: 30) {
        BloomPlusTryBloomHeaderView(canTryForFree: selectedPackage?.hasFreeIntroductoryOffer == true)
          .padding(.top)
          .horizontallyCentered()
          .padding(.horizontal)

        if let package = selectedPackage, package.hasFreeIntroductoryOffer {
          BloomPlusFreeTrialTimelineView(package: package)
            .padding(.horizontal)
        }

        BloomPlusTodayCardShowcaseCell()
        BloomPlusBioAgeMeterView()
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

  var todayInsightFocusedContent: some View {
    VStack {
      VStack(spacing: 30) {
        BloomPlusTodayInsightHeaderView()
          .padding(.top)
          .horizontallyCentered()
          .padding(.horizontal)

        BloomPlusTodayCardShowcaseCell()

        if let package = selectedPackage, package.hasFreeIntroductoryOffer {
          BloomPlusFreeTrialTimelineView(package: package)
            .padding(.horizontal)
        }

        BloomPlusBioAgeMeterView()
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

  var biologicalAgeFocusedContent: some View {
    VStack {
      VStack(spacing: 30) {
        BloomPlusTryBloomHeaderView(canTryForFree: selectedPackage?.hasFreeIntroductoryOffer == true)
          .padding(.top)
          .horizontallyCentered()
          .padding(.horizontal)

        BloomPlusBioAgeMeterView()
          .padding(.horizontal)

        if let package = selectedPackage, package.hasFreeIntroductoryOffer {
          BloomPlusFreeTrialTimelineView(package: package)
            .padding(.horizontal)
        }

        BloomPlusTodayCardShowcaseCell()
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
}

private extension BloomPlusPaywall {

  var purchaseShelf: some View {
    VStack {
      AsyncButton {
        guard let package = selectedPackage ?? viewModel.packages.first else { return }

        try await viewModel.purchase(package)
      } label: {
        Group {
          if let title = selectedPackage?.introductoryPurchaseButtonTitle {
            Text(title)
          } else {
            Text("Invest in my Health")
          }
        }
        .horizontallyCentered()
      }
      .buttonStyle(.primary)

      Group {
        if let eventualCostString = selectedPackage?.introductoryEventualCostDescription {
          Text(eventualCostString)
        } else if let pricingString = selectedPackage?.pricingString {
          Text(pricingString)
        }
      }
      .font(.subheadline)
      .bold()

      HStack {
        Button {
          showOfferCodeSheet.toggle()
        } label: {
          Label("Promo Code", systemSymbol: .tag)
        }
        .bold()
        .frame(minHeight: 50)
        .foregroundStyle(.tint)
        .offerCodeRedemption(isPresented: $showOfferCodeSheet) { result in
            switch result {
            case .failure(let error):
                TelemetryDeck.errorOccurred(
                    id: "BloomPlusPaywall.offerCodeRedemption",
                    category: .thrownException,
                    message: error.localizedDescription
                )
                self.error = error
            default:
                break
            }
        }

        Text("•")
          .foregroundStyle(.tint)

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
    .padding(.horizontal)
    .padding(.top)
  }
}

#Preview("Standard") {
  PreviewEnvironment {
    BloomPlusPaywall()
  }
}

#Preview("Today Insight Focused") {
  PreviewEnvironment {
    BloomPlusPaywall(focus: .todayInsights)
  }
}

#Preview("Biological Age Focused") {
  PreviewEnvironment {
    BloomPlusPaywall(focus: .biologicalAge)
  }
}
