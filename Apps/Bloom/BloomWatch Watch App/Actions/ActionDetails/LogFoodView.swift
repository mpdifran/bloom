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

        // Frequent foods for selected meal
        if provider.hasContent(for: selectedMeal) {
          frequentFoodsSection
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

  private var emptyStateSection: some View {
    Section {
      VStack(spacing: 8) {
        Image(systemName: "fork.knife")
          .font(.title2)
          .foregroundStyle(.secondary)

        Text("No frequent foods")
          .font(.footnote)
          .foregroundStyle(.secondary)

        Text("Log foods on your iPhone to see them here.")
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .multilineTextAlignment(.center)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
    }
  }
}

#Preview {
  LogFoodView(performDismiss: nil)
}
