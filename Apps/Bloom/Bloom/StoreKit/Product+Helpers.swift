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
      return String(localized: "\(subscriptionPeriod) Free", comment: "Intro offer badge on a plan. Placeholder is a period such as 'first month'.")
    }
    return String(localized: "\(introOffer.displayPrice) for \(subscriptionPeriod)", comment: "Intro offer badge on a plan. First placeholder is a price, second is a period such as 'first month'.")
  }

  var introductoryOfferTrialString: String? {
    guard let introOffer = subscription?.introductoryOffer else { return nil }
    
    let subscriptionPeriod = introOffer.period.displayString
    
    if introOffer.price == 0 {
      return String(localized: "\(subscriptionPeriod) Free Trial", comment: "Free trial label. Placeholder is a duration such as '7 days'.")
    }
    return String(localized: "\(introOffer.displayPrice) for \(subscriptionPeriod)", comment: "Intro offer badge on a plan. First placeholder is a price, second is a period such as 'first month'.")
  }

  var introductoryPurchaseButtonTitle: String? {
    guard let introOffer = subscription?.introductoryOffer else { return nil }
    
    let subscriptionPeriod = introOffer.period.displayString
    
    if introOffer.price == 0 {
      return String(localized: "Try Free For \(subscriptionPeriod.capitalized)", comment: "Purchase button title. Placeholder is a duration such as '7 Days'.")
    }
    return String(localized: "\(introOffer.displayPrice) for \(subscriptionPeriod.capitalized)", comment: "Intro offer badge on a plan. First placeholder is a price, second is a period such as 'first month'.")
  }

  var introductoryEventualCostDescription: String? {
    guard 
      let _ = subscription?.introductoryOffer,
      let pricingString
    else { return nil }
    
    if !isMonthly, let monthlyPriceString {
      return String(localized: "then \(pricingString) (\(monthlyPriceString))", comment: "Price shown under the purchase button, ex 'then $49.99 / year ($4.17 / month)'.")
    }
    return String(localized: "then \(pricingString)", comment: "Price shown under the purchase button, ex 'then $9.99 / month'.")
  }

  var sensibleName: String {
    guard let period = subscription?.subscriptionPeriod else {
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
    subscription?.introductoryOffer?.price == 0
  }

  var pricingString: String? {
    guard let period = subscription?.subscriptionPeriod else { return nil }
    
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
    
    return String(localized: "\(displayPrice) / \(periodString)", comment: "A price and its billing period, ex '$9.99 / month'. First placeholder is a price, second is a period.")
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
    
    return String(localized: "\(formattedPrice) / month", comment: "The equivalent monthly price of a longer plan, ex '$4.17 / month'.")
  }
}

extension Product.SubscriptionPeriod {

  var relativeDisplayString: String {
    if value == 1 {
      switch unit {
      case .day:
        return String(localized: "first day", comment: "Intro offer period, as in 'first day Free'.")
      case .week:
        return String(localized: "first week", comment: "Intro offer period, as in 'first week Free'.")
      case .month:
        return String(localized: "first month", comment: "Intro offer period, as in 'first month Free'.")
      case .year:
        return String(localized: "first year", comment: "Intro offer period, as in 'first year Free'.")
      @unknown default:
        return String(localized: "first unit", comment: "Fallback intro offer period for an unrecognized unit.")
      }
    }
    
    switch unit {
    case .day:
      return String(localized: "first \(value) days", comment: "Intro offer period, as in 'first 3 days Free'.")
    case .week:
      return String(localized: "first \(value) weeks", comment: "Intro offer period, as in 'first 2 weeks Free'.")
    case .month:
      return String(localized: "first \(value) months", comment: "Intro offer period, as in 'first 3 months Free'.")
    case .year:
      return String(localized: "first \(value) years", comment: "Intro offer period, as in 'first 2 years Free'.")
    @unknown default:
      return String(localized: "first \(value) units", comment: "Fallback intro offer period for an unrecognized unit.")
    }
  }

  var displayString: String {
    // Split on the count instead of appending an "s" so translators get whole,
    // grammatical strings rather than a stitched-together plural.
    switch unit {
    case .day:
      return value == 1
        ? String(localized: "1 day", comment: "A trial or offer duration.")
        : String(localized: "\(value) days", comment: "A trial or offer duration.")
    case .week:
      return value == 1
        ? String(localized: "1 week", comment: "A trial or offer duration.")
        : String(localized: "\(value) weeks", comment: "A trial or offer duration.")
    case .month:
      return value == 1
        ? String(localized: "1 month", comment: "A trial or offer duration.")
        : String(localized: "\(value) months", comment: "A trial or offer duration.")
    case .year:
      return value == 1
        ? String(localized: "1 year", comment: "A trial or offer duration.")
        : String(localized: "\(value) years", comment: "A trial or offer duration.")
    @unknown default:
      return value == 1
        ? String(localized: "1 unit", comment: "Fallback trial or offer duration for an unrecognized unit.")
        : String(localized: "\(value) units", comment: "Fallback trial or offer duration for an unrecognized unit.")
    }
  }
}
