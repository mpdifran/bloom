//
//  LogFoodView.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI
import BloomFoundation

struct LogFoodView: View {
  let performDismiss: (() -> Void)?

  @State private var provider = WatchFoodProvider.shared
  @State private var selectedMeal: WatchMeal = .suggested
  @State private var selectedFilter: WatchFoodFilter = .frequent
  @State private var selectedFood: WatchFoodItem?
  @State private var showingVoiceLog = false

  private var isBloomPlusUser: Bool {
    WatchSubscriptionProvider.shared.isSubscribed
  }

  var body: some View {
    NavigationStack {
      List {
        // Meal picker
        mealSection

        // Filter picker
        filterSection

        // Content based on selected filter
        if provider.hasContent(for: selectedMeal, filter: selectedFilter) {
          contentSection
        } else {
          emptyStateSection
        }
      }
      .listStyle(.carousel)
      .navigationTitle("Log Food")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination(item: $selectedFood) { food in
        FoodServingView(food: food, meal: selectedMeal, performDismiss: performDismiss)
      }
      .toolbar {
        if isBloomPlusUser {
          ToolbarItem(placement: .topBarTrailing) {
            voiceLogButton
          }
        }
      }
      .frame(maxWidth: .infinity)
      .background(.black)
      .task {
        provider.loadFromApplicationContext()
      }
    }
  }

  // MARK: - Sections

  private var mealSection: some View {
    Section {
      Picker("Meal", selection: $selectedMeal) {
        ForEach(WatchMeal.allCases, id: \.self) { meal in
          Text(meal.displayName).tag(meal)
        }
      }
      .pickerStyle(.navigationLink)
    }
  }

  private var filterSection: some View {
    Section {
      Picker("Filter", selection: $selectedFilter) {
        ForEach(WatchFoodFilter.allCases, id: \.self) { filter in
          Text(filter.displayName).tag(filter)
        }
      }
      .pickerStyle(.navigationLink)
    }
  }

  @ViewBuilder
  private var contentSection: some View {
    switch selectedFilter {
    case .frequent:
      frequentFoodsSection
    case .recent:
      recentFoodsSection
    case .meals:
      mealsSection
    }
  }

  private var voiceLogButton: some View {
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

  private var voiceLogSection: some View {
    Section {
      Button {
        showingVoiceLog = true
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "mic.fill")
            .foregroundStyle(.accent)
          Text("Voice Log")
          Spacer()
        }
      }
    }
    .sheet(isPresented: $showingVoiceLog) {
      VoiceLogView(meal: selectedMeal, performDismiss: {
        showingVoiceLog = false
        performDismiss?()
      })
    }
  }

  private var frequentFoodsSection: some View {
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
      Text("Frequent")
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }

  private var recentFoodsSection: some View {
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
      Text("Recent")
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }

  private var mealsSection: some View {
    Section {
      ForEach(provider.meals) { meal in
        MealCell(meal: meal, selectedMeal: selectedMeal, performDismiss: performDismiss)
      }
    } header: {
      Text("Meals")
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }

  private var emptyStateSection: some View {
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
    }
  }

  private var emptyStateIcon: String {
    switch selectedFilter {
    case .frequent, .recent: return "fork.knife"
    case .meals: return "square.stack"
    }
  }

  private var emptyStateTitle: String {
    switch selectedFilter {
    case .frequent: return "No frequent foods"
    case .recent: return "No recent foods"
    case .meals: return "No saved meals"
    }
  }

  private var emptyStateMessage: String {
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
