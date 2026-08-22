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
      return String(localized: "\(subscriptionPeriod) Free", comment: "Intro offer badge on a plan. Placeholder is a period such as 'first month'.")
    }
    return String(localized: "\(introDiscount.localizedPriceString) for \(subscriptionPeriod)", comment: "Intro offer badge on a plan. First placeholder is a price, second is a period such as 'first month'.")
  }

  var introductoryOfferTrialString: String? {
    guard let introDiscount = storeProduct.introductoryDiscount else { return nil }

    let subscriptionPeriod = introDiscount.subscriptionPeriod.displayString

    if introDiscount.price == 0 {
      return String(localized: "\(subscriptionPeriod) Free Trial", comment: "Free trial label. Placeholder is a duration such as '7 days'.")
    }
    return String(localized: "\(introDiscount.localizedPriceString) for \(subscriptionPeriod)", comment: "Intro offer badge on a plan. First placeholder is a price, second is a period such as 'first month'.")
  }

  /// ex "Try Free For 7 Days"."
  var introductoryPurchaseButtonTitle: String? {
    guard let introDiscount = storeProduct.introductoryDiscount else { return nil }

    let subscriptionPeriod = introDiscount.subscriptionPeriod.displayString

    if introDiscount.price == 0 {
      return String(localized: "Try Free For \(subscriptionPeriod.capitalized)", comment: "Purchase button title. Placeholder is a duration such as '7 Days'.")
    }
    return String(localized: "\(introDiscount.localizedPriceString) for \(subscriptionPeriod.capitalized)", comment: "Intro offer badge on a plan. First placeholder is a price, second is a period such as 'first month'.")
  }

  /// ex "then $49.99/year ($4.17/month)
  var introductoryEventualCostDescription: String? {
    guard
      let _ = storeProduct.introductoryDiscount,
      let pricingString
    else { return nil }

    if !isMonthly, let monthlyPriceString {
      return String(localized: "then \(pricingString) (\(monthlyPriceString))", comment: "Price shown under the purchase button, ex 'then $49.99 / year ($4.17 / month)'.")
    }
    return String(localized: "then \(pricingString)", comment: "Price shown under the purchase button, ex 'then $9.99 / month'.")
  }

  var sensibleName: String {
    guard let period = storeProduct.subscriptionPeriod else {
      return String(localized: "Unknown", comment: "Fallback name for a subscription plan with an unknown billing period.")
    }

    switch period.unit {
    case .month:
      return period.value == 1
        ? String(localized: "Monthly", comment: "Name of a subscription plan billed every month.")
        : String(localized: "\(period.value) Months", comment: "Name of a subscription plan billed every few months.")
    case .year:
      return period.value == 1
        ? String(localized: "Yearly", comment: "Name of a subscription plan billed every year.")
        : String(localized: "\(period.value) Years", comment: "Name of a subscription plan billed every few years.")
    case .week:
      return period.value == 1
        ? String(localized: "Weekly", comment: "Name of a subscription plan billed every week.")
        : String(localized: "\(period.value) Weeks", comment: "Name of a subscription plan billed every few weeks.")
    case .day:
      return period.value == 1
        ? String(localized: "Daily", comment: "Name of a subscription plan billed every day.")
        : String(localized: "\(period.value) Days", comment: "Name of a subscription plan billed every few days.")
    @unknown default:
      return String(localized: "\(period.value) Units", comment: "Fallback name for a subscription plan with an unrecognized billing period.")
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
      periodString = period.value == 1
        ? String(localized: "day", comment: "Billing period in a price, ex '$1.99 / day'.")
        : String(localized: "\(period.value) days", comment: "Billing period in a price, ex '$1.99 / 3 days'.")
    case .week:
      periodString = period.value == 1
        ? String(localized: "week", comment: "Billing period in a price, ex '$1.99 / week'.")
        : String(localized: "\(period.value) weeks", comment: "Billing period in a price, ex '$1.99 / 2 weeks'.")
    case .month:
      periodString = period.value == 1
        ? String(localized: "month", comment: "Billing period in a price, ex '$9.99 / month'.")
        : String(localized: "\(period.value) months", comment: "Billing period in a price, ex '$9.99 / 3 months'.")
    case .year:
      periodString = period.value == 1
        ? String(localized: "year", comment: "Billing period in a price, ex '$49.99 / year'.")
        : String(localized: "\(period.value) years", comment: "Billing period in a price, ex '$49.99 / 2 years'.")
    @unknown default:
      return nil
    }

    // Combine price and period
    return String(localized: "\(localizedPriceString) / \(periodString)", comment: "A price and its billing period, ex '$9.99 / month'. First placeholder is a price, second is a period.")
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

    return String(localized: "\(formattedPrice) / month", comment: "The equivalent monthly price of a longer plan, ex '$4.17 / month'.")
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
