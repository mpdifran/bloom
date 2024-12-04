//
//  TabController.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-23.
//

import SwiftUI
import UserNotifications

enum Tab {
  case today
  case vitals
  case actions
  case nutrition
  case chat
  case profile
}

@Observable @MainActor
final class TabController {
  var activeTab = Tab.today

  var showMorningReport = false
  var showEveningReport = false
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
      select(.chat)
    case .CategoryID.goodMorning:
      dismiss()
      select(.today)
      showMorningReport = true
    case .CategoryID.goodEvening:
      dismiss()
      select(.today)
      showEveningReport = true
    default:
      break
    }
  }
}
