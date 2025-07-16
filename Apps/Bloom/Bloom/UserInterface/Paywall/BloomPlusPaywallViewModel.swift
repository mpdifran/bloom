//
//  BloomPlusPaywallViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-08.
//

import SwiftUI
import RevenueCat
import StoreKit
import TelemetryDeck

extension BloomPlusPaywall {
  @MainActor @Observable
  final class ViewModel {
    var products = [Product]()
  }
}

extension BloomPlusPaywall.ViewModel {

  func loadOfferings() async {
    self.products = PackageStore.shared.subscriptions
  }

  func purchase(_ package: Package) async throws {
    _ = try await Purchases.shared.purchase(package: package)
  }

  func purchase(_ product: Product) async throws {
    _ = try await PackageStore.shared.purchase(product)
  }

  func restorePurchases() async throws {
    try await PackageStore.shared.restore()
  }
}
