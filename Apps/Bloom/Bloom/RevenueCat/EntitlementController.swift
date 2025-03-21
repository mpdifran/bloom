//
//  EntitlementController.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-08.
//

import SwiftUI
import RevenueCat
import Combine

private extension String {
  enum Entitlements {
    static let bloomPro = "Bloom Pro"
  }
}

@MainActor
final class EntitlementController: ObservableObject {
  static let shared = EntitlementController()

  @Published var hasBloomPro: Bool?

  @AppStorage(.FeatureFlag.bypassPaywall) private var bypassPaywall = false

  private init() {
    observeCustomerInfo()
  }

  private var customerInfo: CustomerInfo?

  private var tasks = [Task<Void, Never>]()
  private var bypassPaywallCancellable: AnyCancellable?
}

extension EntitlementController {
  var bloomProEntitlement: EntitlementInfo? {
    customerInfo?.entitlements[.Entitlements.bloomPro]
  }
}

private extension EntitlementController {

  func observeCustomerInfo() {
    tasks.removeAll()

    tasks.append(
      Task.detached { [weak self] in
        for await customerInfo in Purchases.shared.customerInfoStream {
          await self?.handleNewCustomerInfo(customerInfo)
        }
      }
    )
  }

  @MainActor
  func handleNewCustomerInfo(_ customerInfo: CustomerInfo) {
    self.customerInfo = customerInfo

    if bypassPaywall {
      self.hasBloomPro = true
    } else {
      self.hasBloomPro = self.bloomProEntitlement?.isActive == true
    }
  }
}
