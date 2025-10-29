//
//  FoodLoggingActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-06.
//

import SwiftUI
import AppUI
import SwiftData
import DataContainer
import CoreHealth
import BloomModel

extension FoodLoggingActionCardView {
  enum FoodItemHistoryTab: NamedCaseIterable {
    case frequent
    case recent
    case meals

    var name: String {
      switch self {
      case .frequent:
        "Frequent"
      case .recent:
        "Recent"
      case .meals:
        "Meals"
      }
    }
  }
}

struct FoodLoggingActionCardView: View {

  private let initialBarcodeToSearch: String?
  private let performDismiss: (() -> Void)?

  init(
    initialBarcodeToSearch: String? = nil,
    performDismiss: (() -> Void)? = nil
  ) {
    self.initialBarcodeToSearch = initialBarcodeToSearch
    self.performDismiss = performDismiss
  }

  @Bindable private var viewModel = ViewModel()

  @AppStorage("FoodLoggingActionCardView.hasShownExplanation", store: .group) private var hasShownExplanation = false

  @State private var searchQuery = ""
  @State private var shouldAutocomplete = true
  @State private var healthPermissionTrigger = false
  @State private var presentedSheet: AnyView?
  @State private var selectedHistoryTab = FoodItemHistoryTab.frequent

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  @FocusState private var isFocused: Bool

  @ObservedObject private var userController = UserController.shared
  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared
  private var locationViewModel = LocationManagerViewModel.shared

  @Query var meals: [MealRecord]

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        mainView
      }
      .safeAreaInset(edge: .bottom) {
        FoodSearchCard(
          searchQuery: $searchQuery,
          toolbarMode: .logTools,
          onSearch: { searchQuery in
            Task {
              await viewModel.performSearch(for: searchQuery)
            }
          },
          onTextChange: { searchQuery in
            viewModel.debounceSearch(for: searchQuery)
          },
          onUploadNewFood: { foodItem in
            viewModel.didUploadNewFood(foodItem: foodItem)
          },
          performDismiss: performDismiss
        )
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .principal) {
          FoodItemLogPickerHeader()
        }
        ToolbarItem(placement: .cancellationAction) {
          DismissButton(performDismiss: performDismiss)
        }
        ToolbarItem(placement: .primaryAction) {
          Menu {
            Button {
              presentedSheet = CreateEditMealView().asAny
            } label: {
              Label("Create Meal", systemSymbol: .forkKnife)
            }

            Button {
              presentedSheet = FoodUploadScannerView { foodItem in
                viewModel.results = [FoodItemSection(
                  title: "Uploaded Food",
                  category: .branded,
                  foodItems: [foodItem]
                )]
              }.asAny
            } label: {
              Label("Upload a Food", systemSymbol: .plusViewfinder)
            }
          } label: {
            Image(systemSymbol: .plus)
              .bold()
          }
          .menuStyle(.button)
          .buttonStyle(.plain)
        }
      }
    }
    .sheet($presentedSheet)
    .presentationCompactAdaptation(.fullScreenCover)
    .alert(error: $viewModel.error)
    .animation(.default, value: searchQuery)
    .animation(.default, value: viewModel.results)
    .healthDataAccessRequest(
        store: HealthPermissionChecker.shared.healthStore,
        shareTypes: HealthPermissionChecker.shared.writeNutritionTypes,
        readTypes: HealthPermissionChecker.shared.nutritionTypes,
        trigger: healthPermissionTrigger
    ) { result in
      switch result {
      case .success:
        break
      case .failure(let error):
        MainTask {
          self.viewModel.error = error
        }
      }
    }
    .onAppear {
      if let country = locationViewModel.country {
        viewModel.country = country
      }
      locationViewModel.requestLocation()
    }
    .task {
      await checkHealthAuth()
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
    .task {
      guard let initialBarcodeToSearch else { return }

      await viewModel.performBarcodeSearch(for: initialBarcodeToSearch)
    }
    .task {
      // Listen for food logging events and refresh lists
      for await _ in nutritionViewModel.foodLoggedStream {
        await viewModel.fetchRecentFoodItemLogs(for: nutritionViewModel.suggestedMeal)
      }
    }
  }
}

private extension FoodLoggingActionCardView {

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

  var filteredOtherMealsItems: [BloomModel.FoodItem] {
    // Only show when search query is not empty
    guard searchQuery.isNotEmpty else { return [] }

    // Get current meal items to exclude
    let currentMealItemIDs: Set<String> = {
      let localItems = selectedHistoryTab == .frequent ? filteredFrequentItems : filteredRecentItems
      return Set(localItems.map { $0.id.value })
    }()

    // Get other meals items from ViewModel and filter
    return viewModel.otherMealsFoodItemSections
      .flatMap { $0.foodItems }
      .filter { foodItem in
        let matchesSearch = foodItem.contains(searchQuery: searchQuery)
        let notInCurrentMeal = !currentMealItemIDs.contains(foodItem.id.value)
        return matchesSearch && notInCurrentMeal
      }
  }

  var filteredBackendResults: [BloomModel.FoodItem] {
    guard let results = viewModel.results else { return [] }

    // Get IDs of items already shown in current tab and other meals
    let localItemIDs: Set<String> = {
      let currentMealItems = selectedHistoryTab == .frequent ? filteredFrequentItems : filteredRecentItems
      let otherMealsItems = filteredOtherMealsItems
      let allLocalItems = currentMealItems + otherMealsItems
      return Set(allLocalItems.map { $0.id.value })
    }()

    // Filter out items that are already shown locally
    return results
      .flatMap { $0.foodItems }
      .filter { !localItemIDs.contains($0.id.value) }
  }

  @ViewBuilder
  var mainView: some View {
    if let barcode = viewModel.failedBarcodeSearch {
      // Barcode search failed - show upload UI
      failedBarcodeSearchView(barcode: barcode)
    } else if viewModel.isSearching {
      // Only show loading for barcode search
      searchingView
    } else {
      // Always show tab content with tabs visible
      VStack {
        contentWithBackendResults
      }
      .safeAreaInset(edge: .top) {
        foodItemHistoryHeader
          .background(.bar)
      }
      .animation(.easeInOut, value: selectedHistoryTab)
      .groupedBackground()
    }
  }

  @ViewBuilder
  var contentWithBackendResults: some View {
    ScrollView {
      LazyVStack {
        // Show AI Generate button when search query is not empty
        if searchQuery.isNotEmpty {
          aiGenerateButton
        }

        // Show tab-specific content (filtered by searchQuery)
        switch selectedHistoryTab {
        case .frequent:
          frequentTabContent
        case .recent:
          recentTabContent
        case .meals:
          mealsTabContent
        }

        // Show other meals section (only for frequent/recent tabs with search query)
        if selectedHistoryTab != .meals && filteredOtherMealsItems.isNotEmpty {
          otherMealsSection
        }

        // Show backend results below (only for frequent/recent tabs)
        if selectedHistoryTab != .meals && filteredBackendResults.isNotEmpty {
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
      let filteredItems = section.foodItems.filter {
        searchQuery.isEmpty || $0.contains(searchQuery: searchQuery)
      }

      if filteredItems.isNotEmpty {
        SectionTitleView(section.title)
          .padding(.horizontal)

        ForEach(filteredItems) { foodItem in
          FoodItemCell(foodItem: foodItem)
            .id(foodItem.id)
            .transition(.blurReplace)
            .onTapGesture {
              let existingLog = fetchExistingLog(for: foodItem)
              presentedSheet = FoodItemDetailsView(
                foodItem: foodItem,
                existingFoodItemLog: existingLog
              ).asAny
            }
        }
      }
    }
  }

  @ViewBuilder
  var recentTabContent: some View {
    ForEach(viewModel.recentFoodItemSections) { section in
      let filteredItems = section.foodItems.filter {
        searchQuery.isEmpty || $0.contains(searchQuery: searchQuery)
      }

      if filteredItems.isNotEmpty {
        SectionTitleView(section.title)
          .padding(.horizontal)

        ForEach(filteredItems) { foodItem in
          FoodItemCell(foodItem: foodItem)
            .id(foodItem.id)
            .transition(.blurReplace)
            .onTapGesture {
              let existingLog = fetchExistingLog(for: foodItem)
              presentedSheet = FoodItemDetailsView(
                foodItem: foodItem,
                existingFoodItemLog: existingLog
              ).asAny
            }
        }
      }
    }
  }

  @ViewBuilder
  var mealsTabContent: some View {
    if meals.isEmpty {
      ContentUnavailableView {
        Label("No Meals", systemSymbol: .forkKnife)
      } description: {
        Text("You haven't saved any meals yet.")
      } actions: {
        Button {
          presentedSheet = CreateEditMealView().asAny
        } label: {
          Text("Add a Meal")
        }
        .buttonStyle(.primary)
      }
    } else {
      ForEach(meals) { mealRecord in
        if searchQuery.isEmpty || mealRecord.contains(searchQuery: searchQuery) {
          MealRecordCell(mealRecord: mealRecord)
            .transition(.blurReplace)
            .onTapGesture {
              presentedSheet = CreateEditMealView(existingMealRecord: mealRecord).asAny
            }
        }
      }
    }
  }

  @ViewBuilder
  var otherMealsSection: some View {
    SectionTitleView("From Other Meals")
      .padding(.horizontal)

    ForEach(filteredOtherMealsItems) { foodItem in
      FoodItemCell(foodItem: foodItem)
        .id(foodItem.id)
        .transition(.opacity)
        .onTapGesture {
          let existingLog = fetchExistingLog(for: foodItem)
          presentedSheet = FoodItemDetailsView(
            foodItem: foodItem,
            existingFoodItemLog: existingLog
          ).asAny
        }
    }
  }

  @ViewBuilder
  var backendResultsSection: some View {
    SectionTitleView("All Results")
      .padding(.horizontal)

    ForEach(filteredBackendResults) { foodItem in
      FoodItemCell(foodItem: foodItem)
        .id(foodItem.id)
        .transition(.opacity)
        .onTapGesture {
          let existingLog = fetchExistingLog(for: foodItem)
          presentedSheet = FoodItemDetailsView(
            foodItem: foodItem,
            existingFoodItemLog: existingLog
          ).asAny
        }
    }
  }

  var aiGenerateButton: some View {
    Button {
      EntitledAction(presentedSheet: $presentedSheet) {
        Task {
          do {
            try await viewModel.generateWithAI(query: searchQuery, modelContext: modelContext)
            performDismiss?()
          } catch {
            viewModel.error = error
          }
        }
      }
    } label: {
      Label("Generate with AI", systemSymbol: .sparkles)
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.primary)
    .padding(.top, 8)
    .transition(.blurReplace)
  }

  var foodItemHistoryHeader: some View {
    SegmentedPicker(selectedValue: $selectedHistoryTab)
      .padding(.horizontal)
      .padding(.vertical, 8)
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
    .horizontallyCentered()
    .groupedBackground()
  }

  func failedBarcodeSearchView(barcode: String) -> some View {
    VStack {
      Spacer()
      BarcodeView(barcode: barcode)
        .padding(.horizontal)

      Text("No Match")
        .font(.title2)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.secondary)

      Button("Add New Food", systemImage: "plus.viewfinder") {
        presentedSheet = FoodUploadScannerView(barcode: barcode) { foodItem in
          viewModel.didUploadNewFood(foodItem: foodItem)
        }.asAny
      }
      .buttonStyle(.tertiary)
      Spacer()
    }
  }

  var noContentView: some View {
    ContentUnavailableView("No Results", systemImage: "exclamationmark.magnifyingglass")
      .foregroundStyle(.secondary)
  }
}

private extension FoodLoggingActionCardView {

  func checkHealthAuth() async {
    do {
      let authStatus = try await HealthPermissionChecker.shared.checkAccess(
        readTypes: HealthPermissionChecker.shared.nutritionTypes,
        writeTypes: HealthPermissionChecker.shared.writeNutritionTypes
      )

      if authStatus == .shouldRequest {
        healthPermissionTrigger.toggle()
      }
    } catch {
      print(error)
    }
  }

  func fetchExistingLog(for foodItem: BloomModel.FoodItem) -> FoodItemLog? {
    let startOfDay = Calendar.current.startOfDay(for: nutritionViewModel.date)
    let endOfDay = Calendar.current.endOfDay(for: nutritionViewModel.date)
    let mealRawValue = nutritionViewModel.suggestedMeal.rawValue
    let foodItemID = foodItem.id.value

    let descriptor = FetchDescriptor<FoodItemLog>(
      predicate: #Predicate<FoodItemLog> { model in
        model.date >= startOfDay &&
        model.date <= endOfDay &&
        model.mealRawValue == mealRawValue
      }
    )

    let logs = try? modelContext.fetch(descriptor)

    // Find the log that contains this specific food item
    return logs?.first(where: { log in
      log.foodItemServings?.contains(where: { $0.foodItem?.id == foodItemID }) == true
    })
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      FoodLoggingActionCardView()
    }
  }
}
