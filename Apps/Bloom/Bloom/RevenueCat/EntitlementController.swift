//
//  EntitlementController.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-08.
//

import SwiftUI
import RevenueCat
import Combine
import TelemetryDeck

private extension String {
  enum Entitlements {
    static let bloomPro = "Bloom Pro"
  }
  
  enum UserDefaultsKeys {
    static let lastSubscriptionState = "RevenueCat.LastSubscriptionState"
  }
}

@MainActor
final class EntitlementController: ObservableObject {
  static let shared = EntitlementController()

  @Published var hasBloomPro: Bool?

  @AppStorage(.FeatureFlag.bypassPaywall) private var bypassPaywall = false {
    didSet {
      guard bypassPaywall else { return }

      hasBloomPro = true
    }
  }

  private init() {
    loadPreviousSubscriptionState()
    observeCustomerInfo()
  }

  private var customerInfo: CustomerInfo?
  private var previousSubscriptionState: SubscriptionState?

  private var tasks = [Task<Void, Never>]()
  private var bypassPaywallCancellable: AnyCancellable?
}

extension EntitlementController {
  var bloomProEntitlement: EntitlementInfo? {
    customerInfo?.entitlements[.Entitlements.bloomPro]
  }
}

private extension EntitlementController {
  
  func loadPreviousSubscriptionState() {
    guard let data = UserDefaults.group.data(forKey: .UserDefaultsKeys.lastSubscriptionState),
          let state = try? JSONDecoder().decode(SubscriptionState.self, from: data) else {
      return
    }
    previousSubscriptionState = state
  }
  
  func saveSubscriptionState(_ state: SubscriptionState) {
    guard let data = try? JSONEncoder().encode(state) else { return }
    UserDefaults.group.set(data, forKey: .UserDefaultsKeys.lastSubscriptionState)
  }

  func observeCustomerInfo() {
    tasks.removeAll()

    tasks.append(
      Task.detached { [weak self] in
        for await customerInfo in Purchases.shared.customerInfoStream {
          await self?.handleNewCustomerInfo(customerInfo)
        }
      }
    )
  }

  @MainActor
  func handleNewCustomerInfo(_ customerInfo: CustomerInfo) {
    self.customerInfo = customerInfo

    if bypassPaywall {
      self.hasBloomPro = true
    } else {
      self.hasBloomPro = self.bloomProEntitlement?.isActive == true
    }
    
    // Check for subscription cancellation before updating stored state
    checkForSubscriptionCancellation()
    
    // Save current subscription state for next comparison
    if let currentEntitlement = bloomProEntitlement {
      let newState = SubscriptionState(from: currentEntitlement)
      saveSubscriptionState(newState)
      previousSubscriptionState = newState
    }
  }
  
  @MainActor
  func checkForSubscriptionCancellation() {
    guard let currentEntitlement = customerInfo?.entitlements[.Entitlements.bloomPro] else {
      return
    }
    
    // Check if we should send a cancellation event
    let shouldSendCancellationEvent: Bool
    
    if let previousState = previousSubscriptionState {
      // If we have previous state, check if willRenew changed from true to false
      shouldSendCancellationEvent = previousState.willRenew && !currentEntitlement.willRenew && currentEntitlement.isActive
    } else {
      // If no previous state (first launch with this feature), check if current subscription is already cancelled
      shouldSendCancellationEvent = !currentEntitlement.willRenew && currentEntitlement.isActive
    }
    
    if shouldSendCancellationEvent {
      // Determine subscription type
      let subscriptionType: String
      switch currentEntitlement.productIdentifier {
      case .ProductIdentifier.monthly:
        subscriptionType = "monthly"
      case .ProductIdentifier.yearly:
        subscriptionType = "yearly"
      default:
        subscriptionType = "unknown"
      }
      
      // Calculate days since subscription started
      let daysSinceStart: Int
      if let originalPurchaseDate = currentEntitlement.originalPurchaseDate {
        daysSinceStart = Calendar.current.dateComponents([.day], from: originalPurchaseDate, to: Date()).day ?? 0
      } else {
        daysSinceStart = 0
      }
      
      // Send appropriate analytics signal based on period type
      switch currentEntitlement.periodType {
      case .trial:
        TelemetryDeck.signal(
          "Subscription Cancelled During Trial",
          parameters: [
            "subscription_type": subscriptionType,
            "days_since_start": String(daysSinceStart)
          ]
        )
      case .normal:
        TelemetryDeck.signal(
          "Subscription Cancelled During Paid",
          parameters: [
            "subscription_type": subscriptionType,
            "days_since_start": String(daysSinceStart)
          ]
        )
      case .intro:
        TelemetryDeck.signal(
          "Subscription Cancelled During Intro",
          parameters: [
            "subscription_type": subscriptionType,
            "days_since_start": String(daysSinceStart)
          ]
        )
      case .prepaid:
        TelemetryDeck.signal(
          "Subscription Cancelled During Prepaid",
          parameters: [
            "subscription_type": subscriptionType,
            "days_since_start": String(daysSinceStart)
          ]
        )
      }
    }
  }
}
