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

  /// ex "Try Free For 7 Days"."
  var introductoryPurchaseButtonTitle: String? {
    guard let introDiscount = storeProduct.introductoryDiscount else { return nil }

    let subscriptionPeriod = introDiscount.subscriptionPeriod.displayString

    if introDiscount.price == 0 {
      return "Try Free For \(subscriptionPeriod.capitalized)"
    }
    return "\(introDiscount.localizedPriceString) for \(subscriptionPeriod.capitalized)"
  }

  /// ex "then $49.99/year ($4.17/month)
  var introductoryEventualCostDescription: String? {
    guard
      let _ = storeProduct.introductoryDiscount,
      let pricingString
    else { return nil }

    if !isMonthly, let monthlyPriceString {
      return "then \(pricingString) (\(monthlyPriceString))"
    }
    return "then \(pricingString)"
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

  var hasFreeIntroductoryOffer: Bool {
    storeProduct.introductoryDiscount?.price == 0
  }

  var pricingString: String? {
    guard let period = storeProduct.subscriptionPeriod else { return nil }

    // Determine the period string
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

    // Combine price and period
    return "\(localizedPriceString) / \(periodString)"
  }

  var isMonthly: Bool {
    storeProduct.subscriptionPeriod?.unit == .month
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
  
  var trialEndDate: Date? {
    guard let introDiscount = storeProduct.introductoryDiscount,
          introDiscount.price == 0 else { return nil }
    
    let calendar = Calendar.current
    let period = introDiscount.subscriptionPeriod
    
    switch period.unit {
    case .day:
      return calendar.date(byAdding: .day, value: period.value, to: Date())
    case .week:
      return calendar.date(byAdding: .weekOfYear, value: period.value, to: Date())
    case .month:
      return calendar.date(byAdding: .month, value: period.value, to: Date())
    case .year:
      return calendar.date(byAdding: .year, value: period.value, to: Date())
    @unknown default:
      return nil
    }
  }
  
  var trialReminderDate: Date? {
    guard let endDate = trialEndDate else { return nil }
    return Calendar.current.date(byAdding: .day, value: -2, to: endDate)
  }
  
  var trialDurationInDays: Int? {
    guard let introDiscount = storeProduct.introductoryDiscount,
          introDiscount.price == 0 else { return nil }
    
    let period = introDiscount.subscriptionPeriod
    
    switch period.unit {
    case .day:
      return period.value
    case .week:
      return period.value * 7
    case .month:
      return period.value * 30
    case .year:
      return period.value * 365
    @unknown default:
      return nil
    }
  }
}
