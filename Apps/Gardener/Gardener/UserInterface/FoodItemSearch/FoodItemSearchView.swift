//
//  FoodItemSearchView.swift
//  Gardener
//
//  Created by Zach Radford on 2024-12-18.
//

import AdminBloomModel
import SwiftUI

struct FoodItemSearchView: View {

  @StateObject private var foodStore = SearchFoodStore()

  /// Handles only transitioning to no results if a search has ever been attempted.
  @State private var hasSearched = false

  private var searchState: SearchState {
    if foodStore.searchQuery.isEmpty {
      .empty
    } else if foodStore.foodItems.isEmpty && hasSearched {
      .noResults
    } else {
      .results
    }
  }

  private enum SearchState {
    case empty // no search query
    case noResults // no results for query
    case results
  }

  var body: some View {
    Group {
      switch searchState {
      case .empty:
        EmptyStateView(text: "Type a food name, brand name, or barcode")
      case .noResults:
        EmptyStateView(text: "No results found for \(foodStore.searchQuery)")
      case .results:
        resultsList
      }
    }
    .searchable(text: $foodStore.searchQuery, placement: .toolbar, prompt: "Search for food items...")
    .navigationSplitViewColumnWidth(min: 150, ideal: 200, max: 300)
    .onSubmit(of: .search) {
      hasSearched = true
      Task {
        await foodStore.loadItems()
      }
    }
  }
}

private extension FoodItemSearchView {
  var resultsList: some View {
    List(foodStore.foodItems, id: \.id) { item in
      NavigationLink {
        let viewModel = FoodItemDetailViewModel(foodItem: item, foodStore: foodStore)
        FoodItemDetailView(viewModel: viewModel)
      } label: {
        FoodItemCell(
          id: item.id.value,
          name: item.name,
          brandName: item.brandName,
          barCode: item.barcode
        )
        .tag(item)
      }
    }
  }
}

private struct EmptyStateView: View {
  let text: String

  var body: some View {
    VStack(spacing: 24) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 48))
        .foregroundColor(.gray)
      Text(text)
        .font(.headline)
        .foregroundColor(.gray)
        .multilineTextAlignment(.center)
    }
    .padding()
  }
}

private struct FoodItemCell: View {
  let id: String
  let name: String?
  let brandName: String?
  let barCode: String?

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(id)
          .font(.subheadline)
          .foregroundColor(.gray)
        Text(name ?? "No Name")
          .font(.headline)
        if let brandName {
          Text(brandName)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        if let barCode {
          Text(barCode)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      }
    }
    .padding(.vertical, 8)
  }
}
