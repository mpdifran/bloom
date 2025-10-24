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
import CoreNetwork
import Combine
import BloomFoundation
import SwiftData

extension FoodItemPicker {
  @Observable @MainActor
  final class ViewModel {
    var isSearching = false
    var results: [FoodItemSection]?
    var frequentFoodItemSections = [FoodItemSection]()
    var recentFoodItemSections = [FoodItemSection]()
    var country: String = "usa"
    var error: Error?

    private var debounceTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?
    private var lastSearchedQuery: String = ""

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

  func debounceSearch(for query: String) {
    // Cancel previous debounce task
    debounceTask?.cancel()
    // Cancel previous search task
    searchTask?.cancel()

    guard query.isNotEmpty else {
      results = nil
      return
    }

    debounceTask = Task {
      await Delay(500) // 0.5 seconds
      await performSearch(for: query)
    }
  }

  func performSearch(for query: String) async {
    // Skip if already searched this exact query
    guard query != lastSearchedQuery else { return }

    // Cancel any existing search
    searchTask?.cancel()

    results = nil

    guard query.isNotEmpty else {
      lastSearchedQuery = ""
      return
    }

    searchTask = Task {
      do {
        // Fetch backend results
        let sections = try await NetworkRequester.shared.foodSearch(
          name: query,
          brand: nil,
          preferredCountry: country
        )

        // Check if task was cancelled
        guard !Task.isCancelled else { return }

        // Store backend results directly - deduplication handled at View level
        self.results = sections.map {
          FoodItemSection(
            title: "All Results",
            category: .branded,
            foodItems: $0.foods
          )
        }

        // Update last searched query after successful search
        self.lastSearchedQuery = query

        // Upsert food items in the background
        let foodItems = sections.flatMap { $0.foods }
        Task.detached {
          await FoodItemUpsertProcessor.shared.upsertFoodItems(foodItems)
        }
      } catch {
        guard !Task.isCancelled else { return }
        self.error = error
      }
    }

    await searchTask?.value
  }
}
