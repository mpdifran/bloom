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

  var statusCellInfo: EntitlementStatusCellInfo? {
    guard let expirationDate else { return nil }

    if !willRenew {
      if isActive, expirationDate > .now {
        return EntitlementStatusCellInfo(
          title: "Expires",
          date: expirationDate
        )
      } else {
        return EntitlementStatusCellInfo(
          title: "Expired",
          date: expirationDate
        )
      }
    } else {
      switch periodType {
      case .intro:
        return EntitlementStatusCellInfo(
          title: "Intro Rate Ends",
          date: expirationDate
        )
      case .normal:
        return EntitlementStatusCellInfo(
          title: "Next Charge Date",
          date: expirationDate
        )
      case .trial:
        return EntitlementStatusCellInfo(
          title: "Free Trial Ends",
          date: expirationDate
        )
      case .prepaid:
        return EntitlementStatusCellInfo(
          title: "Prepaid Period Ends",
          date: expirationDate
        )
      }
    }
  }
}

struct EntitlementStatusCellInfo {
  let title: String
  let date: Date
}
