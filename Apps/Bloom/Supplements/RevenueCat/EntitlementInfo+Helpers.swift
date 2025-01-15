//
//  EntitlementInfo+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-15.
//

import Foundation
import RevenueCat

extension EntitlementInfo {

  var activeSubscriptionName: String {
    switch productIdentifier {
    case .ProductIdentifier.monthly:
      "Monthly"
    case .ProductIdentifier.yearly:
      "Yearly"
    default:
      "Subscription"
    }
  }
}
