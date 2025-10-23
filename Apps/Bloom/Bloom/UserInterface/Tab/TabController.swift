//
//  TabController.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-23.
//

import SwiftUI
@preconcurrency import UserNotifications
import RevenueCat
import TelemetryDeck
import SFSafeSymbols
import DataContainer

enum Tab: CaseIterable, Identifiable {
  var id: Self { self }

  case today
  case nutrition
  case vitals
  case workouts
}

extension Tab {

  var name: String {
    switch self {
    case .today:
      "Today"
    case .vitals:
      "You"
    case .nutrition:
      "Nutrition"
    case .workouts:
      "Workouts"
    }
  }

  var tabImage: Image {
    switch self {
    case .today:
      Image(.todayTab)
    case .vitals:
      Image(systemSymbol: .figure)
    case .nutrition:
      Image(.nutritionTab)
    case .workouts:
      Image(.workoutsTab)
    }
  }
}

struct ChatContext: Identifiable, Hashable, Sendable, Codable {
  var id: Int { hashValue }

  let title: String
  let context: String
}

@Observable @MainActor
final class TabController {
  var activeTab = Tab.today
  var isShowingChat = false
  var chatContexts = [ChatContext]()
  var chatLauncherSafeAreaInset: CGFloat = 0

  var showPaywall = false
  var toggleToDismiss = false
  var pendingVitalNavigation: VitalModel.Kind?

  private var notificationCenterDelegate: NotificationCenterDelegate!

  init() {
    self.notificationCenterDelegate = NotificationCenterDelegate { [weak self] response in
      Task {
        await MainActor.run {
          self?.handle(response: response)
        }
      }
    }
  }
}

extension TabController {

  func select(_ tab: Tab) {
    activeTab = tab
  }

  func dismiss() {
    toggleToDismiss.toggle()
  }
}

private extension TabController {

  func handle(response: UNNotificationResponse) {
    switch response.notification.request.content.categoryIdentifier {
    case .CategoryID.chatMessage:
      dismiss()
//      select(.chat)
    case .CategoryID.reminders:
      dismiss()
      select(.today)
    case .CategoryID.trialReminder:
      dismiss()
      Task {
        do {
          try await Purchases.shared.showManageSubscriptions()
          TelemetryDeck.signal("View Manage Subscriptions")
        } catch {
          print("TabController: Failed to show manage subscriptions: \(error)")
        }
      }
    default:
      break
    }
  }
}
