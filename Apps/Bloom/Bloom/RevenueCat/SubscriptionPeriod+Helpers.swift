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
        return String(localized: "first day", comment: "Free trial length on the paywall")
      case .week:
        return String(localized: "first week", comment: "Free trial length on the paywall")
      case .month:
        return String(localized: "first month", comment: "Free trial length on the paywall")
      case .year:
        return String(localized: "first year", comment: "Free trial length on the paywall")
      @unknown default:
        return String(localized: "first unit", comment: "Free trial length on the paywall")
      }
    }

    switch unit {
    case .day:
      return String(localized: "first \(value) days", comment: "Free trial length on the paywall")
    case .week:
      return String(localized: "first \(value) weeks", comment: "Free trial length on the paywall")
    case .month:
      return String(localized: "first \(value) months", comment: "Free trial length on the paywall")
    case .year:
      return String(localized: "first \(value) years", comment: "Free trial length on the paywall")
    @unknown default:
      return String(localized: "first \(value) units", comment: "Free trial length on the paywall")
    }
  }

  /// Returns something like "1 week" or "2 months".
  ///
  /// Singular and plural are separate branches rather than an inline `s` suffix: a suffix hack
  /// extracts as an unusable key and doesn't survive translation to languages with other plural
  /// rules.
  var displayString: String {
    if value == 1 {
      switch unit {
      case .day:
        return String(localized: "1 day", comment: "Subscription period length")
      case .week:
        return String(localized: "1 week", comment: "Subscription period length")
      case .month:
        return String(localized: "1 month", comment: "Subscription period length")
      case .year:
        return String(localized: "1 year", comment: "Subscription period length")
      @unknown default:
        return String(localized: "1 unit", comment: "Subscription period length")
      }
    }

    switch unit {
    case .day:
      return String(localized: "\(value) days", comment: "Subscription period length")
    case .week:
      return String(localized: "\(value) weeks", comment: "Subscription period length")
    case .month:
      return String(localized: "\(value) months", comment: "Subscription period length")
    case .year:
      return String(localized: "\(value) years", comment: "Subscription period length")
    @unknown default:
      return String(localized: "\(value) units", comment: "Subscription period length")
    }
  }
}
