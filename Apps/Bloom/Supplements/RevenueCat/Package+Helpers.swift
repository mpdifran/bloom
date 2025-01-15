//
//  Package+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-14.
//

import Foundation
import RevenueCat

extension Package {

  var introductoryOfferString: String? {
    guard let introDiscount = storeProduct.introductoryDiscount else { return nil }

    let subscriptionPeriod = introDiscount.subscriptionPeriod.relativeDisplayString

    if introDiscount.price == 0 {
      return "\(subscriptionPeriod) Free"
    }
    return "\(introDiscount.localizedPriceString) for \(subscriptionPeriod)"
  }

  var introductoryOfferTrialString: String? {
    guard let introDiscount = storeProduct.introductoryDiscount else { return nil }

    let subscriptionPeriod = introDiscount.subscriptionPeriod.displayString

    if introDiscount.price == 0 {
      return "\(subscriptionPeriod) Free Trial"
    }
    return "\(introDiscount.localizedPriceString) for \(subscriptionPeriod)"
  }

  var sensibleName: String {
    guard let period = storeProduct.subscriptionPeriod else {
      return "Unknown"
    }

    switch period.unit {
    case .month:
      return period.value == 1 ? "Monthly" : "\(period.value) Months"
    case .year:
      return period.value == 1 ? "Yearly" : "\(period.value) Years"
    case .week:
      return period.value == 1 ? "Weekly" : "\(period.value) Weeks"
    case .day:
      return period.value == 1 ? "Daily" : "\(period.value) Days"
    @unknown default:
      return "\(period.value) Units"
    }
  }

  var monthlyPriceString: String? {
    guard let period = storeProduct.subscriptionPeriod else { return nil }

    let price = storeProduct.price

    // Calculate the total number of months in the subscription period
    let months: Int
    switch period.unit {
    case .day:
      months = period.value / 30
    case .week:
      months = (period.value * 7) / 30
    case .month:
      months = period.value
    case .year:
      months = period.value * 12
    @unknown default:
      return nil
    }

    // Avoid division by zero
    guard months > 0 else { return nil }

    // Calculate the equivalent monthly price
    let monthlyPrice = price / Decimal(months)
    let formattedPrice = NumberFormatter.localizedString(
      from: monthlyPrice as NSNumber,
      number: .currency
    )

    return "\(formattedPrice) / month"
  }
}
