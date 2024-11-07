//
//  FoodLoggingActionCardViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-06.
//

import SwiftUI

private extension Int {
    static let debounceTime: Int = 300
}

extension FoodLoggingActionCardView {

    @Observable @MainActor
    final class ViewModel {
        var autocomplete = [String]()
        var results = [Supplements.Components.Schemas.Food]()
        var error: Error?

        private var debouncedSearchQuery = ""
        private var debounceTask: Task<Void, Never>?
    }
}

extension FoodLoggingActionCardView.ViewModel {

    func debounceAutocomplete(for query: String) {
        debounceTask?.cancel()

        guard query.isNotEmpty else { return }

        debounceTask = Task {
            await Delay(.debounceTime)
            await performAutocomplete(query: query)
        }
    }

    func performSearch(for query: String) async {
        autocomplete.removeAll()

        do {
            self.results = try await NetworkRequester.shared.edamamFoodSearch(query: query)
        } catch {
            self.error = error
        }
    }
}

private extension FoodLoggingActionCardView.ViewModel {

    func performAutocomplete(query: String) async {
        guard query.isNotEmpty else { return }

        do {
            let response = try await NetworkRequester.shared.edamamFoodAutocomplete(query: query)
            autocomplete = response
        } catch { }
    }
}
