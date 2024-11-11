//
//  FoodLoggingActionCardViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-06.
//

import SwiftUI
import BloomModel

private extension Int {
    static let debounceTime: Int = 300
}

extension FoodLoggingActionCardView.ViewModel {
    enum Meal: String, CaseIterable {
        case breakfast
        case lunch
        case dinner
        case snack

        var name: String {
            self.rawValue.capitalized
        }
    }
}

extension FoodLoggingActionCardView {

    @Observable @MainActor
    final class ViewModel {
        var meal = Meal.breakfast
        var autocomplete = [String]()
        var isSearching = false
        var results: [FoodItem]?
        var error: Error?

        private var debouncedSearchQuery = ""
        private var debounceTask: Task<Void, Never>?
    }
}

extension FoodLoggingActionCardView.ViewModel {

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
            self.results = try await NetworkRequester.shared.foodSearch(name: query, brand: nil)
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
            self.results = try await NetworkRequester.shared.foodSearch(upcCode: barcode)
        } catch {
            self.error = error
        }
    }
}

private extension FoodLoggingActionCardView.ViewModel {

    func performAutocomplete(query: String) async {
        guard query.isNotEmpty else { return }

        do {
            self.autocomplete = try await NetworkRequester.shared.foodAutocomplete(query: query)
        } catch { }
    }
}
