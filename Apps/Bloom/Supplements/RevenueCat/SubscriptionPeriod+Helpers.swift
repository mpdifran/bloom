//
//  SubscriptionPeriod+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-08.
//

import RevenueCat

extension SubscriptionPeriod {

  var displayString: String {
    switch unit {
    case .day:
      return "\(value) day\(value > 1 ? "s" : "")"
    case .week:
      return "\(value) week\(value > 1 ? "s" : "")"
    case .month:
      return "\(value) month\(value > 1 ? "s" : "")"
    case .year:
      return "\(value) year\(value > 1 ? "s" : "")"
    @unknown default:
      return "\(value) unit\(value > 1 ? "s" : "")"
    }
  }
}
