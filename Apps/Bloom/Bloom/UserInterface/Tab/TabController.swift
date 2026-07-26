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

enum TabKind: CaseIterable, Identifiable {
  var id: Self { self }

  case today
  case nutrition
  case you
  case workouts
  case actions
}

extension TabKind {

  var name: String {
    switch self {
    case .today:
      "Today"
    case .you:
      "You"
    case .nutrition:
      "Nutrition"
    case .workouts:
      "Workouts"
    case .actions:
      "Actions"
    }
  }

  var tabImage: Image {
    switch self {
    case .today:
      Image(.todayTab)
    case .you:
      Image(systemSymbol: .figure)
    case .nutrition:
      Image(.nutritionTab)
    case .workouts:
      Image(.workoutsTab)
    case .actions:
      Image(systemSymbol: .plus)
    }
  }
}

struct ChatContext: Identifiable, Hashable, Sendable, Codable {
  var id: Int { hashValue }

  let title: String
  let context: String
  let source: Source

  enum Source: String, Codable, Hashable, Sendable {
    case todayInsight
    case monitorInsight

    var systemPromptPrefix: String {
      switch self {
      case .todayInsight:
        return "The user is asking a question about these insights from the Today View:"
      case .monitorInsight:
        return "The user is asking a question about this AI insight from a Health Monitor:"
      }
    }
  }
}

@Observable @MainActor
final class TabController {
  var activeTab = TabKind.today
  var isShowingChat = false
  /// When opening chat, focus the new-message bar immediately (e.g. from the Chat with Bud accessory).
  var shouldFocusNewChatOnOpen = false
  var chatContexts = [ChatContext]()
  var chatLauncherSafeAreaInset: CGFloat = 0

  var toggleToDismiss = false
  var pendingVitalNavigation: VitalModel.Kind?
  var pendingGoalNavigation: String?
  var pendingFoodItemLogNavigation: String?
  var pendingFoodItemNavigation: String?
  var pendingSavedMealNavigation: String?
  var pendingYearInBloomNavigation: Int?
  var pendingMonitorNavigation: MonitorType?
  var pendingWorkoutNavigation: String?
  var pendingStepsNavigation = false

  private var notificationCenterDelegate: NotificationCenterDelegate!

  init() {
    self.notificationCenterDelegate = NotificationCenterDelegate { [weak self] response in
      self?.handle(response: response)
    }
  }
}

extension TabController {

  func select(_ tab: TabKind) {
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
    case .CategoryID.monitorAlert:
      dismiss()
      select(.you)
      if let monitorTypeRaw = response.notification.request.content.userInfo["monitorType"] as? String,
         let monitorType = MonitorType(rawValue: monitorTypeRaw) {
        pendingMonitorNavigation = monitorType
      }
    case .CategoryID.workoutCompletion:
      dismiss()
      select(.workouts)
      if let workoutUUID = response.notification.request.content.userInfo["workoutUUID"] as? String {
        pendingWorkoutNavigation = workoutUUID
      }
    default:
      break
    }
  }
}
