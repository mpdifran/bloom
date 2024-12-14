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

private extension Int {
  static let debounceTime: Int = 300
}

struct FoodItemSection: Equatable, Identifiable {
  var id: String { title }

  let title: String
  let foodItems: [BloomModel.FoodItem]
}

extension FoodLoggingActionCardView {

  @Observable @MainActor
  final class ViewModel {
    var autocomplete = [String]()
    var isSearching = false
    var results: [FoodItemSection]?
    var failedBarcodeSearch: String?
    var error: Error?
    var recentFoodItemSections = [FoodItemSection]()
    var country: FoodCountry = .usa

    private var debouncedSearchQuery = ""
    private var debounceTask: Task<Void, Never>?

    private let foodItemModelActor = FoodItemLogModelActor(modelContainer: ContainerHolder.shared.container)
  }
}

extension FoodLoggingActionCardView.ViewModel {

  func fetchRecentFoodItemLogs(for meal: FoodItemLog.Meal) async {
    do {
      let recentLogs = try await foodItemModelActor.fetchRecentLogs(for: meal, limit: 10)

      let foodItems = recentLogs
        .compactMap({ $0.foodItem?.asNetworkFoodItem() })
        .makingUnique()

      if foodItems.isNotEmpty {
        recentFoodItemSections = [FoodItemSection(title: "Recent", foodItems: foodItems)]
      } else {
        recentFoodItemSections = []
      }
    } catch {
      print(error)
    }
  }

  func debounceAutocomplete(for query: String) {
    debounceTask?.cancel()

    guard query.isNotEmpty else {
      autocomplete.removeAll()
      return
    }

    debounceTask = Task {
      await Delay(.debounceTime)
      await performAutocomplete(query: query)
    }
  }

  func performSearch(for query: String) async {
    results = []

    defer { isSearching = false }
    isSearching = true

    autocomplete.removeAll()

    do {
      let sections = try await NetworkRequester.shared.foodSearch(
        name: query,
        brand: nil,
        preferredCountry: country
      )

      self.results = sections.map({ FoodItemSection(title: $0.title, foodItems: $0.foods) })
      self.autocomplete.removeAll()
    } catch {
      self.error = error
    }
  }

  func performBarcodeSearch(for barcode: String) async {
    results = []

    defer { isSearching = false }
    isSearching = true

    autocomplete.removeAll()

    do {
      let sections = try await NetworkRequester.shared.foodSearch(
        upcCode: barcode,
        country: country
      )

      guard sections.contains(where: { $0.foods.isNotEmpty }) else {
        failedBarcodeSearch = barcode
        results = []
        TelemetryDeck.signal("Food Item Barcode Scan - Fail")
        return
      }

      TelemetryDeck.signal("Food Item Barcode Scan - Match")
      self.results = sections.map({ FoodItemSection(title: $0.title, foodItems: $0.foods) })
    } catch {
      self.error = error
    }
  }

  func didUploadNewFood(foodItem: FoodItem) {
    let section = FoodItemSection(
      title: "Uploaded Food",
      foodItems: [foodItem]
    )

    failedBarcodeSearch = nil
    isSearching = false
    autocomplete.removeAll()
    results = [section]
  }
}

private extension FoodLoggingActionCardView.ViewModel {

  func performAutocomplete(query: String) async {
    guard query.isNotEmpty else { return }

    failedBarcodeSearch = nil
    results = nil

    do {
      self.autocomplete = try await NetworkRequester.shared.foodAutocomplete(query: query)
    } catch { }
  }
}
