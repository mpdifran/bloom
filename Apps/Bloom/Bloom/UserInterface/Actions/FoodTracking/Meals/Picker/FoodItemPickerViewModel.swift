//
//  FoodItemPickerViewModel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-26.
//

import SwiftUI
import BloomModel
import DataContainer
import TelemetryDeck

extension FoodItemPicker {
  @Observable @MainActor
  final class ViewModel {
    var isSearching = false
    var results: [FoodItemSection]?
    var frequentFoodItemSections = [FoodItemSection]()
    var recentFoodItemSections = [FoodItemSection]()
    var country: String = "usa"
    var error: Error?

    private let foodItemModelActor = FoodItemLogModelActor.standard()
  }
}

extension FoodItemPicker.ViewModel {

  func fetchRecentFoodItemLogs(for meal: FoodItemLog.Meal) async {
    do {
      let frequentFoodItems = try await foodItemModelActor.fetchFrequentLogs(for: meal)

      if frequentFoodItems.isNotEmpty {
        frequentFoodItemSections = [
          FoodItemSection(
            title: "Frequently Logged",
            category: .branded,
            foodItems: frequentFoodItems.makingUnique().map({ $0.asNetworkFoodItem() })
          )
        ]
      } else {
        frequentFoodItemSections = []
      }

      let recentFoodItems = try await foodItemModelActor.fetchRecentLogs(for: meal)

      if recentFoodItems.isNotEmpty {
        recentFoodItemSections = [
          FoodItemSection(
            title: "Recently Logged",
            category: .branded,
            foodItems: recentFoodItems.makingUnique().map({ $0.asNetworkFoodItem() })
          )
        ]
      } else {
        recentFoodItemSections = []
      }
    } catch {
      print(error)
    }
  }

  func performSearch(for query: String) async {
    results = nil

    guard query.isNotEmpty else { return }

    defer { isSearching = false }
    isSearching = true

    do {
      let sections = try await NetworkRequester.shared.foodSearch(
        name: query,
        brand: nil,
        preferredCountry: country
      )

      self.results = sections.map(
        {
          FoodItemSection(
            title: $0.title,
            category: $0.category,
            foodItems: $0.foods
          )
      })
    } catch {
      self.error = error
    }
  }
}
