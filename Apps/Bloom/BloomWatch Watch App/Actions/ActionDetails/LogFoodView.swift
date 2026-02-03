//
//  LogFoodView.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI
import BloomFoundation
import SFSafeSymbols

struct LogFoodView: View {
  let performDismiss: (() -> Void)?

  @State private var provider = WatchFoodProvider.shared
  @State private var selectedMeal: WatchMeal = .suggested
  @State private var selectedFilter: WatchFoodFilter = .frequent
  @State private var selectedFood: WatchFoodItem?
  @State private var searchText = ""
  @State private var searchResults: [WatchFoodItem] = []
  @State private var isSearching = false
  @State private var showingVoiceLog = false
  @FocusState private var isSearchFieldFocused: Bool

  private var isBloomPlusUser: Bool {
    WatchSubscriptionProvider.shared.isSubscribed
  }

  var body: some View {
    NavigationStack {
      List {
        controlsSection
        contentSection
      }
      .listStyle(.carousel)
      .navigationTitle("Log Food")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination(item: $selectedFood) { food in
        FoodServingView(food: food, meal: selectedMeal, performDismiss: performDismiss)
      }
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          searchBarSection
        }
        if isBloomPlusUser {
          ToolbarItem(placement: .topBarTrailing) {
            voiceLogButton
          }
        }
      }
      .frame(maxWidth: .infinity)
      .background(.black)
      .animation(.default, value: searchText)
      .task {
        provider.loadFromApplicationContext()
      }
    }
  }
}

private extension LogFoodView {

  // MARK: - Sections

  var searchBarSection: some View {
    TextField("Search", text: $searchText)
      .focused($isSearchFieldFocused)
      .onChange(of: searchText) { _, newValue in
        if newValue.isNotEmpty {
          performSearch(query: newValue)
        } else {
          searchResults = []
        }
      }
  }

  var controlsSection: some View {
    Section {
      Picker("Meal", selection: $selectedMeal) {
        ForEach(WatchMeal.allCases, id: \.self) { meal in
          Text(meal.displayName).tag(meal)
        }
      }
      .pickerStyle(.navigationLink)

      if searchText.isEmpty {
        Picker("Filter", selection: $selectedFilter) {
          ForEach(WatchFoodFilter.allCases, id: \.self) { filter in
            Text(filter.displayName).tag(filter)
          }
        }
        .pickerStyle(.navigationLink)
      }
    } header: {
      Text("Details")
    }
  }

  @ViewBuilder
  var contentSection: some View {
    if searchText.isNotEmpty {
      searchResultsSection
    } else if provider.hasContent(for: selectedMeal, filter: selectedFilter) {
      switch selectedFilter {
      case .frequent:
        frequentFoodsSection
      case .recent:
        recentFoodsSection
      case .meals:
        mealsSection
      }
    } else {
      emptyStateSection
    }
  }

  var searchResultsSection: some View {
    Section {
      if isSearching {
        ProgressView()
          .frame(maxWidth: .infinity)
      } else if searchResults.isEmpty {
        VStack(spacing: 8) {
          Image(systemName: "magnifyingglass")
            .font(.title2)
            .foregroundStyle(.secondary)
          Text("No results")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
      } else {
        ForEach(searchResults) { food in
          Button {
            selectedFood = food
          } label: {
            FoodCell(food: food)
          }
          .buttonStyle(.plain)
        }
      }
    } header: {
      Text("Results")
    }
  }

  func performSearch(query: String) {
    isSearching = true

    Task {
      let message = WatchFoodSearchMessage(query: query)
      guard let data = try? JSONEncoder.watch.encode(message) else {
        isSearching = false
        return
      }

      do {
        let responseData = try await WatchChannel.shared.send(data: data)
        let response = try JSONDecoder.watch.decode(WatchFoodSearchResponse.self, from: responseData)

        if response.success {
          searchResults = response.foods
        }
      } catch {
        // Handle error silently
      }

      isSearching = false
    }
  }

  var searchButton: some View {
    Button {
      if searchText.isEmpty {
        isSearchFieldFocused = true
      } else {
        // Clear search
        searchText = ""
        searchResults = []
      }
    } label: {
      Label(
        searchText.isEmpty ? "Search" : "Clear",
        systemSymbol: searchText.isEmpty ? .magnifyingglass : .xmark
      )
    }
  }

  var voiceLogButton: some View {
    Button {
      showingVoiceLog = true
    } label: {
      Label("Voice Log", systemSymbol: .microphoneFill)
    }
    .tint(.mutedOrange)
    .sheet(isPresented: $showingVoiceLog) {
      VoiceLogView(meal: selectedMeal, performDismiss: {
        showingVoiceLog = false
        performDismiss?()
      })
    }
  }

  var frequentFoodsSection: some View {
    Section {
      ForEach(provider.foods(for: selectedMeal)) { food in
        Button {
          selectedFood = food
        } label: {
          FoodCell(food: food)
        }
        .buttonStyle(.plain)
      }
    } header: {
      Text("Results")
    }
  }

  var recentFoodsSection: some View {
    Section {
      ForEach(provider.recentFoods(for: selectedMeal)) { food in
        Button {
          selectedFood = food
        } label: {
          FoodCell(food: food)
        }
        .buttonStyle(.plain)
      }
    } header: {
      Text("Results")
    }
  }

  var mealsSection: some View {
    Section {
      ForEach(provider.meals) { meal in
        MealCell(meal: meal, selectedMeal: selectedMeal, performDismiss: performDismiss)
      }
    } header: {
      Text("Results")
    }
  }

  var emptyStateSection: some View {
    Section {
      VStack(spacing: 8) {
        Image(systemName: emptyStateIcon)
          .font(.title2)
          .foregroundStyle(.secondary)

        Text(emptyStateTitle)
          .font(.footnote)
          .foregroundStyle(.secondary)

        Text(emptyStateMessage)
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .multilineTextAlignment(.center)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
    } header: {
      Text("Results")
    }
  }

  var emptyStateIcon: String {
    switch selectedFilter {
    case .frequent, .recent: return "fork.knife"
    case .meals: return "square.stack"
    }
  }

  var emptyStateTitle: String {
    switch selectedFilter {
    case .frequent: return "No frequent foods"
    case .recent: return "No recent foods"
    case .meals: return "No saved meals"
    }
  }

  var emptyStateMessage: String {
    switch selectedFilter {
    case .frequent: return "Log foods on your iPhone to see them here."
    case .recent: return "Log foods on your iPhone to see them here."
    case .meals: return "Create meals on your iPhone to see them here."
    }
  }
}

#Preview {
  LogFoodView(performDismiss: nil)
}
