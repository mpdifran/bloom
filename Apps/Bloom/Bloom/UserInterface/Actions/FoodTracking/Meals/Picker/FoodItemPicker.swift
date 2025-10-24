//
//  FoodItemPicker.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-26.
//

import SwiftUI
import AppUI
import BloomModel
import DataContainer
import CoreHealth

extension FoodItemPicker {
  enum FoodItemHistoryTab: NamedCaseIterable {
    case frequent
    case recent

    var name: String {
      switch self {
      case .frequent:
        return "Frequent"
      case .recent:
        return "Recent"
      }
    }
  }
}

struct FoodItemPicker: View {
  let selectionHandler: (FoodItem) -> Void

  init(selectionHandler: @escaping (FoodItem) -> Void) {
    self.selectionHandler = selectionHandler
  }

  @Bindable private var viewModel = ViewModel()

  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared

  @State private var searchQuery = ""
  @State private var selectedHistoryTab = FoodItemHistoryTab.frequent
  @State private var presentedSheet: AnyView?

  @Environment(\.dismiss) private var dismiss

  private var locationViewModel = LocationManagerViewModel.shared

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        contentView
      }
      .horizontallyCentered()
      .groupedBackground()
      .navigationTitle("Select a Food")
      .navigationBarTitleDisplayMode(.inline)
      .safeAreaInset(edge: .bottom) {
        FoodSearchCard(
          searchQuery: $searchQuery,
          toolbarMode: .pickerTools,
          onSearch: { searchQuery in
            Task {
              await viewModel.performSearch(for: searchQuery)
            }
          },
          onTextChange: { searchQuery in
            Task {
              await viewModel.debounceSearch(for: searchQuery)
            }
          },
          onUploadNewFood: { foodItem in
            // Do nothing since tools are disabled.
          },
          onFoodItemPicked: { foodItem in
            select(foodItem: foodItem)
          }
        )
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .principal) {
          MealPicker()
        }
      }
    }
    .animation(.default, value: searchQuery)
    .animation(.default, value: nutritionViewModel.suggestedMeal)
    .animation(.default, value: viewModel.frequentFoodItemSections)
    .animation(.default, value: viewModel.recentFoodItemSections)
    .animation(.default, value: viewModel.results)
    .sheet($presentedSheet)
    .alert(error: $viewModel.error)
    .presentationCompactAdaptation(.fullScreenCover)
    .onAppear {
      if let country = locationViewModel.country {
        viewModel.country = country
      }
      locationViewModel.requestLocation()
    }
    .task {
      await viewModel.fetchRecentFoodItemLogs(for: nutritionViewModel.suggestedMeal)
    }
    .onChange(of: nutritionViewModel.suggestedMeal) { _, newValue in
      Task {
        await viewModel.fetchRecentFoodItemLogs(for: newValue)
      }
    }
    .onChange(of: locationViewModel.country) { _, newValue in
      guard let country = newValue else { return }

      viewModel.country = country
    }
  }
}

private extension FoodItemPicker {

  var filteredFrequentItems: [BloomModel.FoodItem] {
    viewModel.frequentFoodItemSections
      .flatMap { $0.foodItems }
      .filter { searchQuery.isEmpty || $0.contains(searchQuery: searchQuery) }
  }

  var filteredRecentItems: [BloomModel.FoodItem] {
    viewModel.recentFoodItemSections
      .flatMap { $0.foodItems }
      .filter { searchQuery.isEmpty || $0.contains(searchQuery: searchQuery) }
  }

  var filteredBackendResults: [BloomModel.FoodItem] {
    guard let results = viewModel.results else { return [] }

    // Get IDs of items already shown in current tab
    let localItemIDs: Set<String> = {
      let localItems = selectedHistoryTab == .frequent ? filteredFrequentItems : filteredRecentItems
      return Set(localItems.map { $0.id.value })
    }()

    // Filter out items that are already shown locally
    return results
      .flatMap { $0.foodItems }
      .filter { !localItemIDs.contains($0.id.value) }
  }

  @ViewBuilder
  var contentView: some View {
    // Always show tab content with tabs visible
    VStack {
      contentWithBackendResults
    }
    .safeAreaInset(edge: .top) {
      foodItemHistoryHeader
        .background(.bar)
    }
    .animation(.easeInOut, value: selectedHistoryTab)
  }

  @ViewBuilder
  var contentWithBackendResults: some View {
    ScrollView {
      LazyVStack {
        // Show tab-specific content (filtered by searchQuery)
        switch selectedHistoryTab {
        case .frequent:
          frequentTabContent
        case .recent:
          recentTabContent
        }

        // Show backend results below
        if filteredBackendResults.isNotEmpty {
          backendResultsSection
        }
      }
      .padding(.horizontal)
      .padding(.bottom)
    }
  }

  @ViewBuilder
  var frequentTabContent: some View {
    ForEach(viewModel.frequentFoodItemSections) { section in
      SectionTitleView(section.title)

      ForEach(section.foodItems) { foodItem in
        if searchQuery.isEmpty || foodItem.contains(searchQuery: searchQuery) {
          FoodItemPickerCell(foodItem: foodItem) {
            select(foodItem: foodItem)
          }
          .id(foodItem.id)
          .transition(.blurReplace)
          .onTapGesture {
            presentedSheet = FoodItemDetailsView(
              foodItem: foodItem,
              existingFoodItemLog: nil,
              mode: .viewOnly
            ).asAny
          }
        }
      }
    }
  }

  @ViewBuilder
  var recentTabContent: some View {
    ForEach(viewModel.recentFoodItemSections) { section in
      SectionTitleView(section.title)

      ForEach(section.foodItems) { foodItem in
        if searchQuery.isEmpty || foodItem.contains(searchQuery: searchQuery) {
          FoodItemPickerCell(foodItem: foodItem) {
            select(foodItem: foodItem)
          }
          .id(foodItem.id)
          .transition(.blurReplace)
          .onTapGesture {
            presentedSheet = FoodItemDetailsView(
              foodItem: foodItem,
              existingFoodItemLog: nil,
              mode: .viewOnly
            ).asAny
          }
        }
      }
    }
  }

  @ViewBuilder
  var backendResultsSection: some View {
    SectionTitleView("All Results")

    ForEach(filteredBackendResults) { foodItem in
      FoodItemPickerCell(foodItem: foodItem) {
        select(foodItem: foodItem)
      }
      .id(foodItem.id)
      .transition(.opacity)
      .onTapGesture {
        presentedSheet = FoodItemDetailsView(
          foodItem: foodItem,
          existingFoodItemLog: nil,
          mode: .viewOnly
        ).asAny
      }
    }
  }

  var foodItemHistoryHeader: some View {
    SegmentedPicker(selectedValue: $selectedHistoryTab)
      .padding(.horizontal)
      .padding(.vertical, 8)
  }
}

private extension FoodItemPicker {

  func select(foodItem: FoodItem) {
    selectionHandler(foodItem)
    dismiss()
  }
}

#Preview {
  PreviewEnvironment {
    FoodItemPicker() { _ in

    }
  }
}
