//
//  EntitlementController.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-08.
//

import Foundation
import RevenueCat

private extension String {
  enum Entitlements {
    static let bloomPro = "Bloom Pro"
  }
}

@MainActor @Observable
final class EntitlementController {
  static let shared = EntitlementController()

  var hasBloomPro: Bool?

  private init() {
    observeCustomerInfo()
  }

  private var customerInfo: CustomerInfo?

  private var tasks = [Task<Void, Never>]()
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
    self.hasBloomPro = self.bloomProEntitlement?.isActive == true
  }
}
