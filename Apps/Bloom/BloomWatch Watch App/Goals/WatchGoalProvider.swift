//
//  WatchGoalProvider.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-02-01.
//

import Foundation
import BloomFoundation

/// Provides goal data on watchOS by reading from WatchConnectivity application context.
@Observable @MainActor
public final class WatchGoalProvider {
  public static let shared = WatchGoalProvider()

  private static let goalsKey = "WatchGoalProvider.goals"
  private static let lastUpdatedKey = "WatchGoalProvider.lastUpdated"

  public private(set) var goals: [WatchGoal] = [] {
    didSet { saveToUserDefaults() }
  }

  public private(set) var lastUpdated: Date? {
    didSet { saveToUserDefaults() }
  }

  public var hasGoals: Bool {
    goals.isNotEmpty
  }

  private init() {
    loadFromUserDefaults()
    loadFromApplicationContext()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleApplicationContextUpdate),
      name: WatchChannel.applicationContextDidUpdate,
      object: nil
    )

    // Listen for priority complication updates
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleComplicationUserInfo(_:)),
      name: WatchChannel.complicationUserInfoDidReceive,
      object: nil
    )
  }

  @objc private func handleApplicationContextUpdate() {
    loadFromApplicationContext()
  }

  @objc private func handleComplicationUserInfo(_ notification: Notification) {
    // The WatchChannel already stored the data in UserDefaults and triggered widget refresh,
    // but we also want to update our in-memory state for the watch app UI
    guard let userInfo = notification.userInfo,
          userInfo[WatchChannel.goalsDataKey] != nil else {
      return
    }
    loadFromUserDefaults()
  }

  /// Loads goal data from WatchConnectivity application context
  public func loadFromApplicationContext() {
    guard let data = WatchChannel.shared.getApplicationContextData(for: WatchChannel.goalsDataKey),
          let watchData = try? JSONDecoder.watch.decode(WatchGoalData.self, from: data) else {
      return
    }

    // Track if data changed
    let hasNewData = goals != watchData.goals || lastUpdated != watchData.lastUpdated

    goals = watchData.goals
    lastUpdated = watchData.lastUpdated

    // Refresh the widget timeline if data changed
    if hasNewData {
      WidgetRefreshManager.shared.reloadWatchGoalWidget()
    }
  }

  private func loadFromUserDefaults() {
    if let goalsData = UserDefaults.group.data(forKey: Self.goalsKey) {
      do {
        goals = try JSONDecoder.watch.decode([WatchGoal].self, from: goalsData)
      } catch {
        print("Failed to decode goals, clearing cache: \(error)")
        UserDefaults.group.removeObject(forKey: Self.goalsKey)
        goals = []
      }
    }

    if let timestamp = UserDefaults.group.object(forKey: Self.lastUpdatedKey) as? Double {
      lastUpdated = Date(timeIntervalSince1970: timestamp)
    }
  }

  private func saveToUserDefaults() {
    if let data = try? JSONEncoder.watch.encode(goals) {
      UserDefaults.group.set(data, forKey: Self.goalsKey)
    }

    if let lastUpdated {
      UserDefaults.group.set(lastUpdated.timeIntervalSince1970, forKey: Self.lastUpdatedKey)
    }
  }

  /// Gets a specific goal by ID
  public func goal(withId id: String) -> WatchGoal? {
    goals.first { $0.id == id }
  }

  /// Gets the first available goal (useful for default selection)
  public func firstGoal() -> WatchGoal? {
    goals.first
  }
}
