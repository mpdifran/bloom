//
//  SubscriptionState.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-06.
//

import Foundation
import RevenueCat

struct SubscriptionState: Codable {
  let willRenew: Bool
  let periodTypeRawValue: Int
  let productIdentifier: String
  let originalPurchaseDate: Date?
  let isActive: Bool
  
  init(from entitlement: EntitlementInfo) {
    self.willRenew = entitlement.willRenew
    self.periodTypeRawValue = entitlement.periodType.rawValue
    self.productIdentifier = entitlement.productIdentifier
    self.originalPurchaseDate = entitlement.originalPurchaseDate
    self.isActive = entitlement.isActive
  }
  
  var periodType: PeriodType {
    PeriodType(rawValue: periodTypeRawValue) ?? .normal
  }
}
