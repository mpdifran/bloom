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
  @State private var didSearchToggle = false
  @State private var healthPermissionTrigger = false
  @State private var presentedSheet: AnyView?
  @State private var selectedTab = FoodItemCategoryTab.branded
  @State private var userControllerViewModel = UserControllerViewModel()

  @Environment(\.dismiss) private var dismiss

  @FocusState private var isFocused: Bool

  private let nutritionViewModel = NutritionTrackingViewModel.shared
  private var locationViewModel = LocationManagerViewModel.shared

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        mainView
        Divider()
        suggestionsBarView
        foodSearchTextBar
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .principal) {
          FoodItemLogPickerHeader()
        }
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") {
            if let performDismiss {
              performDismiss()
            } else {
              dismiss()
            }
          }
          .bold()
        }
      }
    }
    .sheet($presentedSheet)
    .presentationDetents([.large])
    .presentationCornerRadius(25)
    .presentationCompactAdaptation(.fullScreenCover)
    .alert(error: $viewModel.error)
    .animation(.default, value: selectedTab)
    .tint(.mutedGreen)
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
      let isAuthenticated = await UserController.shared.isAuthenticated
      if !isAuthenticated {
        await MainActor.run {
          presentedSheet = LoginView {
            if !userControllerViewModel.isAuthenticated {
              dismiss()
            }
          }.asAny
        }
      }
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
  }
}

private extension FoodLoggingActionCardView {

  @ViewBuilder
  var mainView: some View {
    if viewModel.isSearching {
      searchingView
    } else if let results = viewModel.results {
      if results.isNotEmpty {
        resultsView(results: results)
      } else if let barcode = viewModel.failedBarcodeSearch {
        failedBarcodeSearchView(barcode: barcode)
      } else {
        noContentView
      }
    } else {
      recentFoodItemsView
    }
  }

  var recentFoodItemsView: some View {
    ScrollView {
      LazyVStack {
        ForEach(viewModel.recentFoodItemSections) { section in
          SectionTitleView(section.title)
            .padding(.horizontal)

          ForEachEnumerated(section.foodItems) { index, food in
            FoodItemCell(food: food)
              .id(food.id)
              .transition(.blurReplace)
              .onTapGesture {
                presentedSheet = FoodItemDetailsView(
                  foodItem: food,
                  existingFoodItemLog: nil
                ).asAny
              }
          }
        }
      }
      .padding()
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

  func resultsView(results: [FoodItemSection]) -> some View {
    Group {
      if let section = results.first(where: { $0.category == selectedTab.category }) {
        ScrollView {
          LazyVStack {
            TabFilter(selectedTab: $selectedTab)

            ForEachEnumerated(section.foodItems) { index, food in
              FoodItemCell(food: food)
                .id(food.id)
                .transition(.opacity)
                .onTapGesture {
                  presentedSheet = FoodItemDetailsView(
                    foodItem: food,
                    existingFoodItemLog: nil
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

  var suggestionsBarView: some View {
    ScrollView(.horizontal) {
      HStack {
        if viewModel.autocomplete.isNotEmpty {
          ForEachEnumerated(viewModel.autocomplete) { (index, autocomplete) in
            FoodSearchAutocompleteCell(query: autocomplete)
              .transition(.scale)
              .onTapGesture {
                shouldAutocomplete = false
                searchQuery = autocomplete
                performSearch()
                Delay(100) {
                  shouldAutocomplete = true
                }
              }
          }
        } else if searchQuery.isEmpty {
          FoodSearchToolCell(title: "Magic Scan", systemImage: "sparkles")
            .onTapGesture {
              #if DEBUG
                // TODO: Check flag
              presentedSheet = AIFoodScannerExplanationView {
                Task {
                  await Delay(300)
                  await MainActor.run {
                    presentedSheet = AIFoodScannerView().asAny
                  }
                }
              }.asAny
              #else
              presentedSheet = AIFoodScannerView().asAny
              #endif
            }
          FoodSearchToolCell(title: "Scan Barcode", systemImage: "barcode.viewfinder")
            .onTapGesture {
              presentedSheet = FoodBarcodeScannerView { barcode in
                isFocused = false
                Task {
                  await viewModel.performBarcodeSearch(for: barcode)
                }
              }.asAny
            }
          FoodSearchToolCell(title: "Add New Food", systemImage: "plus.viewfinder")
            .onTapGesture {
              presentedSheet = FoodUploadScannerView() { foodItem in
                viewModel.didUploadNewFood(foodItem: foodItem)
              }.asAny
            }
        }
      }
      .padding(.horizontal)
    }
    .scrollIndicators(.hidden)
    .animation(.bouncy, value: viewModel.autocomplete)
    .padding(.top, 8)
  }

  var foodSearchTextBar: some View {
    HStack {
      TextField(
        "",
        text: $searchQuery,
        prompt: Text("What did you eat?")
      )
      .submitLabel(.search)
      .onSubmit {
        performSearch()
      }
      .padding()
      .onChange(of: searchQuery) { oldValue, newValue in
        guard shouldAutocomplete else { return }

        viewModel.debounceAutocomplete(for: searchQuery)
      }

      Button {
        performSearch()
      } label: {
        Image(systemName: "magnifyingglass.circle.fill")
          .font(.largeTitle)
          .foregroundStyle(.white, .tint)
      }
      .sensoryFeedback(.impact, trigger: didSearchToggle)
    }
    .focused($isFocused)
    .padding(.horizontal, 8)
    .background {
      Capsule()
        .fill(.background.secondary)
        .onTapGesture {
          isFocused = true
        }
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
  }
}

private extension FoodLoggingActionCardView {

  func performSearch() {
    didSearchToggle.toggle()
    isFocused = false
    Task {
      await viewModel.performSearch(for: searchQuery)
    }
  }

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
}

#Preview {
  PreviewSheetPresent {
    FoodLoggingActionCardView()
  }
}
