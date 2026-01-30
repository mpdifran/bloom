//
//  WatchFoodProvider.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-01-30.
//

import Foundation
import BloomFoundation

/// Provides frequent foods data on watchOS by reading from WatchConnectivity application context.
@Observable @MainActor
public final class WatchFoodProvider {
  public static let shared = WatchFoodProvider()

  private static let foodDataKey = "WatchFoodProvider.foodData"

  public private(set) var foodData: WatchFoodData? {
    didSet { saveToUserDefaults() }
  }

  /// Returns whether any meal has frequent foods
  public var hasContent: Bool {
    guard let foodData else { return false }
    return foodData.breakfastFoods.isNotEmpty ||
           foodData.lunchFoods.isNotEmpty ||
           foodData.dinnerFoods.isNotEmpty ||
           foodData.snackFoods.isNotEmpty
  }

  /// Returns whether the specified meal has frequent foods
  public func hasContent(for meal: WatchMeal) -> Bool {
    foods(for: meal).isNotEmpty
  }

  /// Returns the frequent foods for the specified meal
  public func foods(for meal: WatchMeal) -> [WatchFoodItem] {
    foodData?.foods(for: meal) ?? []
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
  }

  @objc private func handleApplicationContextUpdate() {
    loadFromApplicationContext()
  }

  /// Loads food data from WatchConnectivity application context
  public func loadFromApplicationContext() {
    guard let data = WatchChannel.shared.getApplicationContextData(for: WatchChannel.foodDataKey),
          let decoded = try? JSONDecoder().decode(WatchFoodData.self, from: data) else {
      return
    }

    foodData = decoded
  }

  private func loadFromUserDefaults() {
    if let data = UserDefaults.group.data(forKey: Self.foodDataKey) {
      do {
        foodData = try JSONDecoder().decode(WatchFoodData.self, from: data)
      } catch {
        print("Failed to decode food data, clearing cache: \(error)")
        UserDefaults.group.removeObject(forKey: Self.foodDataKey)
        foodData = nil
      }
    }
  }

  private func saveToUserDefaults() {
    if let foodData, let data = try? JSONEncoder().encode(foodData) {
      UserDefaults.group.set(data, forKey: Self.foodDataKey)
    }
  }
}
