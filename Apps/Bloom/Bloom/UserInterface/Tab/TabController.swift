//
//  TabController.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-23.
//

import SwiftUI
import UserNotifications

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
      "Vitals"
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
      Image(.vitalsTab)
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

  var showMorningReport = false
  var showEveningReport = false
  var showFocusAreasReview = false
  var showPaywall = false
  var toggleToDismiss = false

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
    case .CategoryID.goodMorning:
      dismiss()
      select(.today)
      // Check Bloom Plus entitlement before showing morning report
      if EntitlementController.shared.hasBloomPro == true {
        showMorningReport = true
      } else {
        showPaywall = true
      }
    case .CategoryID.goodEvening:
      dismiss()
      select(.today)
      showEveningReport = true
    case .CategoryID.reminders:
      dismiss()
      select(.today)
    default:
      break
    }
  }
}
