//
//  SubscriptionPeriod+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-08.
//

import RevenueCat

extension SubscriptionPeriod {

  /// Returns something like "first day" or "first 2 months".
  var relativeDisplayString: String {
    if value == 1 {
      switch unit {
      case .day:
        return "first day"
      case .week:
        return "first week"
      case .month:
        return "first month"
      case .year:
        return "first year"
      @unknown default:
        return "first unit"
      }
    }

    switch unit {
    case .day:
      return "first \(value) days"
    case .week:
      return "first \(value) weeks"
    case .month:
      return "first \(value) months"
    case .year:
      return "first \(value) years"
    @unknown default:
      return "first \(value) units"
    }
  }

  /// Returns something like "1 week" or "2 months".
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
