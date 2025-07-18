//
//  Product+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-16.
//

import Foundation
import StoreKit

extension Product {

  var introductoryOfferString: String? {
    guard let introOffer = subscription?.introductoryOffer else { return nil }
    
    let subscriptionPeriod = introOffer.period.relativeDisplayString
    
    if introOffer.price == 0 {
      return "\(subscriptionPeriod) Free"
    }
    return "\(introOffer.displayPrice) for \(subscriptionPeriod)"
  }

  var introductoryOfferTrialString: String? {
    guard let introOffer = subscription?.introductoryOffer else { return nil }
    
    let subscriptionPeriod = introOffer.period.displayString
    
    if introOffer.price == 0 {
      return "\(subscriptionPeriod) Free Trial"
    }
    return "\(introOffer.displayPrice) for \(subscriptionPeriod)"
  }

  var introductoryPurchaseButtonTitle: String? {
    guard let introOffer = subscription?.introductoryOffer else { return nil }
    
    let subscriptionPeriod = introOffer.period.displayString
    
    if introOffer.price == 0 {
      return "Try Free For \(subscriptionPeriod.capitalized)"
    }
    return "\(introOffer.displayPrice) for \(subscriptionPeriod.capitalized)"
  }

  var introductoryEventualCostDescription: String? {
    guard 
      let _ = subscription?.introductoryOffer,
      let pricingString
    else { return nil }
    
    if !isMonthly, let monthlyPriceString {
      return "then \(pricingString) (\(monthlyPriceString))"
    }
    return "then \(pricingString)"
  }

  var sensibleName: String {
    guard let period = subscription?.subscriptionPeriod else {
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

  var hasFreeIntroductoryOffer: Bool {
    subscription?.introductoryOffer?.price == 0
  }

  var pricingString: String? {
    guard let period = subscription?.subscriptionPeriod else { return nil }
    
    let periodString: String
    switch period.unit {
    case .day:
      periodString = period.value == 1 ? "day" : "\(period.value) days"
    case .week:
      periodString = period.value == 1 ? "week" : "\(period.value) weeks"
    case .month:
      periodString = period.value == 1 ? "month" : "\(period.value) months"
    case .year:
      periodString = period.value == 1 ? "year" : "\(period.value) years"
    @unknown default:
      return nil
    }
    
    return "\(displayPrice) / \(periodString)"
  }

  var isMonthly: Bool {
    subscription?.subscriptionPeriod.unit == .month
  }

  var monthlyPriceString: String? {
    guard let period = subscription?.subscriptionPeriod else { return nil }
    
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
    
    guard months > 0 else { return nil }
    
    let monthlyPrice = price / Decimal(months)
    let formattedPrice = NumberFormatter.localizedString(
      from: monthlyPrice as NSNumber,
      number: .currency
    )
    
    return "\(formattedPrice) / month"
  }
}

extension Product.SubscriptionPeriod {

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
