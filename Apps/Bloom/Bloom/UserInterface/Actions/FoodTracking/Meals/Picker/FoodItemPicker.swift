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

struct FoodItemPicker: View {
  let selectionHandler: (FoodItem) -> Void

  init(selectionHandler: @escaping (FoodItem) -> Void) {
    self.selectionHandler = selectionHandler
  }

  @Bindable private var viewModel = ViewModel()

  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared

  @State private var searchQuery = ""
  @State private var selectedTab = FoodItemCategoryTab.branded
  @State private var selectedHistoryTab = FoodLoggingActionCardView.FoodItemHistoryTab.frequent
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
          enableTools: false
        ) { searchQuery in
          Task {
            await viewModel.performSearch(for: searchQuery)
          }
        } onUploadNewFood: { foodItem in
          // Do nothing since tools are disabled.
        }
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

  @ViewBuilder
  var contentView: some View {
    if viewModel.isSearching {
      searchingView
    } else if let results = viewModel.results {
      if results.isNotEmpty {
        resultsView(results: results)
      } else {
        noContentView
      }
    } else {
      frequentLogsView
    }
  }

  var searchingView: some View {
    VStack {
      Spacer()
      ProgressView()
        .tint(.secondary)
      Text("Looking up foods...")
        .font(.title2)
        .bold()
        .foregroundStyle(.secondary)
      Spacer()
    }
  }

  var noContentView: some View {
    ContentUnavailableView("No Results", systemImage: "exclamationmark.magnifyingglass")
      .foregroundStyle(.secondary)
  }

  var frequentLogsView: some View {
    VStack {
      switch selectedHistoryTab {
      case .frequent:
        frequentFoodItemsView
      case .recent:
        recentFoodItemsView
      case .meals:
        EmptyView()
      }
    }
    .safeAreaInset(edge: .top) {
      foodItemHistoryHeader
        .background(.bar)
    }
    .animation(.easeInOut, value: selectedHistoryTab)
  }

  var foodItemHistoryHeader: some View {
    Picker("", selection: $selectedHistoryTab) {
      Text("Frequent")
        .bold()
        .fontDesign(.rounded)
        .tag(FoodLoggingActionCardView.FoodItemHistoryTab.frequent)
      Text("Recent")
        .bold()
        .fontDesign(.rounded)
        .tag(FoodLoggingActionCardView.FoodItemHistoryTab.recent)
    }
    .pickerStyle(.segmented)
    .padding(.horizontal)
    .padding(.vertical, 12)
  }

  var frequentFoodItemsView: some View {
    ScrollView {
      LazyVStack {
        ForEach(viewModel.frequentFoodItemSections) { section in
          SectionTitleView(section.title)
            .padding(.horizontal)

          ForEachEnumerated(section.foodItems) { index, foodItem in
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
      .padding(.horizontal)
      .padding(.bottom)
    }
  }

  var recentFoodItemsView: some View {
    ScrollView {
      LazyVStack {
        ForEach(viewModel.recentFoodItemSections) { section in
          SectionTitleView(section.title)
            .padding(.horizontal)

          ForEachEnumerated(section.foodItems) { index, foodItem in
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
      .padding(.horizontal)
      .padding(.bottom)
    }
  }

  func resultsView(results: [FoodItemSection]) -> some View {
    Group {
      if let section = results.first(where: { $0.category == selectedTab.category }) {
        ScrollView {
          LazyVStack {
            TabFilter(selectedTab: $selectedTab)

            ForEachEnumerated(section.foodItems) { index, food in
              FoodItemPickerCell(foodItem: food) {
                select(foodItem: food)
              }
              .id(food.id)
              .transition(.opacity)
              .onTapGesture {
                presentedSheet = FoodItemDetailsView(
                  foodItem: food,
                  existingFoodItemLog: nil,
                  mode: .viewOnly
                ).asAny
              }
            }
          }
          .padding()
        }
      } else {
        VStack {
          TabFilter(selectedTab: $selectedTab)

          ContentUnavailableView {
            Label {
              Text("No Results")
            } icon: {
              selectedTab.image
            }
          }
        }
        .padding()
      }
    }
    .animation(.bouncy, value: viewModel.results)
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
