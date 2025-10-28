//
//  FoodLoggingActionCardViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-06.
//

import SwiftUI
import BloomModel
import DataContainer
import TelemetryDeck
import CoreNetwork
import BloomFoundation
import SwiftData
import CoreHealth

private extension Int {
  static let debounceTime: Int = 300
}

struct FoodItemSection: Equatable, Identifiable {
  var id: String { title }

  let title: String
  let category: FoodItem.Category
  let foodItems: [BloomModel.FoodItem]
}

extension FoodLoggingActionCardView {

  @Observable @MainActor
  final class ViewModel {
    var isSearching = false
    var results: [FoodItemSection]?
    var failedBarcodeSearch: String?
    var error: Error?
    var frequentFoodItemSections = [FoodItemSection]()
    var recentFoodItemSections = [FoodItemSection]()
    var otherMealsFoodItemSections = [FoodItemSection]()
    var country: String = "usa"

    private var debounceTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?
    private var lastSearchedQuery: String = ""

    private let foodItemModelActor = FoodItemLogModelActor.standard()
  }
}

extension FoodLoggingActionCardView.ViewModel {

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

      let otherMealsFoodItems = try await foodItemModelActor.fetchRecentLogsExcludingMeal(excluding: meal)

      if otherMealsFoodItems.isNotEmpty {
        otherMealsFoodItemSections = [
          FoodItemSection(
            title: "From Other Meals",
            category: .branded,
            foodItems: otherMealsFoodItems.makingUnique().map({ $0.asNetworkFoodItem() })
          )
        ]
      } else {
        otherMealsFoodItemSections = []
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

  func performBarcodeSearch(for barcode: String) async {
    results = []

    defer { isSearching = false }
    isSearching = true

    do {
      let sections = try await NetworkRequester.shared.foodSearch(
        upcCode: barcode,
        country: country
      )

      guard sections.contains(where: { $0.foods.isNotEmpty }) else {
        failedBarcodeSearch = barcode
        results = []
        TelemetryDeck.signal("Food Item Barcode Scan", parameters: ["barcodeScanResult": "Fail"])
        return
      }

      TelemetryDeck.signal("Food Item Barcode Scan", parameters: ["barcodeScanResult": "Match"])
      self.results = sections.map({
        FoodItemSection(
          title: $0.title,
          category: .branded,
          foodItems: $0.foods
        )
      })

      // Upsert food items in the background
      let foodItems = sections.flatMap { $0.foods }
      Task.detached {
        await FoodItemUpsertProcessor.shared.upsertFoodItems(foodItems)
      }
    } catch {
      self.error = error
    }
  }

  func didUploadNewFood(foodItem: FoodItem) {
    let section = FoodItemSection(
      title: "Uploaded Food",
      category: .branded,
      foodItems: [foodItem]
    )

    failedBarcodeSearch = nil
    isSearching = false
    results = [section]
  }

  func generateWithAI(query: String, modelContext: ModelContext) async throws {
    // Generate identifier upfront
    let processingIdentifier = AIFoodProcessingIdentifier()

    // Upload to backend first
    _ = try await NetworkRequester.shared.uploadMagicScan(
      imageData: nil,
      contextText: query,
      processingIdentifier: processingIdentifier
    )

    // Only save locally if upload succeeded
    NutritionTrackingViewModel.shared.logTextOnlyMagicScan(
      modelContext: modelContext,
      processingIdentifier: processingIdentifier,
      contextText: query,
      date: NutritionTrackingViewModel.shared.date,
      meal: NutritionTrackingViewModel.shared.suggestedMeal
    )

    TelemetryDeck.signal("ai_text_generation_initiated")
  }
}
