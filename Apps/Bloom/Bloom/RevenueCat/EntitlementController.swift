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
    static let isSubscribed = "RevenueCat.IsSubscribed"
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
  
  /// Maximum number of goals (habits) a user can create
  var maxGoals: Int? {
    // Return nil for unlimited, or a specific number for limited
    hasBloomPro == true ? nil : 3
  }
  
  /// Maximum number of reminders a user can create
  var maxReminders: Int? {
    // Return nil for unlimited, or a specific number for limited
    hasBloomPro == true ? nil : 1
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
    // Also save simple boolean for widget access
    UserDefaults.group.set(state.isActive, forKey: .UserDefaultsKeys.isSubscribed)
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
    
    // Handle trial reminder notifications based on current state
    handleTrialReminderNotifications()
    
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
  func handleTrialReminderNotifications() {
    guard let currentEntitlement = customerInfo?.entitlements[.Entitlements.bloomPro] else {
      return
    }

    if currentEntitlement.periodType == .trial && currentEntitlement.isActive {
      // User is in a trial - schedule notification using actual expiration date
      if let expirationDate = currentEntitlement.expirationDate,
         let reminderDate = Calendar.current.date(byAdding: .day, value: -2, to: expirationDate) {
        Task {
          await NotificationManager.shared.scheduleTrialReminderNotification(for: reminderDate)
        }
      }
    } else if currentEntitlement.periodType == .normal && currentEntitlement.isActive {
      // User is on a paid subscription - cancel any trial reminders
      Task {
        await NotificationManager.shared.cancelTrialReminderNotification()
      }
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
      case .ProductIdentifier.weeklyLower:
        subscriptionType = "weekly"
      case .ProductIdentifier.monthly, .ProductIdentifier.monthlyHalf, .ProductIdentifier.monthlyLower:
        subscriptionType = "monthly"
      case .ProductIdentifier.yearly, .ProductIdentifier.yearlyHalf, .ProductIdentifier.yearlyLower:
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
