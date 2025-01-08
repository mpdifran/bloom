//
//  BloomPlusPaywallViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-08.
//

import SwiftUI
import RevenueCat
import TelemetryDeck

extension BloomPlusPaywall {
  @MainActor @Observable
  final class ViewModel {
    var packages = [Package]()
  }
}

extension BloomPlusPaywall.ViewModel {

  func loadOfferings() async {
    do {
      let offerings = try await Purchases.shared.offerings()
      self.packages = offerings.current?.availablePackages ?? []
    } catch {
      TelemetryDeck.errorOccurred(
        id: "BloomPlusPaywall.ViewModel.loadOfferings",
        category: .thrownException,
        message: error.localizedDescription
      )
    }
  }

  func purchase(_ package: Package) async throws {
    _ = try await Purchases.shared.purchase(package: package)
  }

  func restorePurchases() async throws {
    _ = try await Purchases.shared.restorePurchases()
  }
}
