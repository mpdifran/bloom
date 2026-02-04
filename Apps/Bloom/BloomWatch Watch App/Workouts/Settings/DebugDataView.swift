//
//  DebugDataView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-02-02.
//

import SwiftUI
import BloomFoundation

struct DebugDataView: View {
  private let foodProvider = WatchFoodProvider.shared
  private let todayProvider = TodayProvider.shared
  private let goalProvider = WatchGoalProvider.shared
  private let unitProvider = WatchUnitPreferencesProvider.shared
  private let subscriptionProvider = WatchSubscriptionProvider.shared
  private let pendingFoodLogManager = PendingFoodLogManager.shared

  var body: some View {
    List {
      foodDataSection
      todayDataSection
      goalsSection
      subscriptionSection
      unitPreferencesSection
      pendingEntriesSection
    }
    .listStyle(.carousel)
    .navigationTitle("Debug Data")
  }
}

// MARK: - Sections

private extension DebugDataView {

  var foodDataSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionHeader("Food Data")

      if let foodData = foodProvider.foodData {
        debugRow("Breakfast", "\(foodData.breakfastFoods.count) items")
        debugRow("Lunch", "\(foodData.lunchFoods.count) items")
        debugRow("Dinner", "\(foodData.dinnerFoods.count) items")
        debugRow("Snack", "\(foodData.snackFoods.count) items")
        debugRow("Recent Breakfast", "\(foodData.recentBreakfastFoods.count)")
        debugRow("Recent Lunch", "\(foodData.recentLunchFoods.count)")
        debugRow("Recent Dinner", "\(foodData.recentDinnerFoods.count)")
        debugRow("Recent Snack", "\(foodData.recentSnackFoods.count)")
        debugRow("Saved Meals", "\(foodData.meals.count)")
        debugRow("Last Updated", formatDate(foodData.lastUpdated))
      } else {
        Text("No food data")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 16)
  }

  var todayDataSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionHeader("Today Data")

      debugRow("Advice", todayProvider.todaysAdvice != nil ? "Present" : "None")
      debugRow("Reminders", "\(todayProvider.reminders.count)")

      if let lastUpdated = todayProvider.lastUpdated {
        debugRow("Last Updated", formatDate(lastUpdated))
      }

      if todayProvider.reminders.isNotEmpty {
        Divider()
        Text("Reminders:")
          .font(.caption2)
          .foregroundStyle(.secondary)
        ForEach(todayProvider.reminders.prefix(5)) { reminder in
          Text("- \(reminder.title) (\(reminder.status.rawValue))")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        if todayProvider.reminders.count > 5 {
          Text("... and \(todayProvider.reminders.count - 5) more")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(.vertical, 16)
  }

  var goalsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionHeader("Goals")

      debugRow("Count", "\(goalProvider.goals.count)")

      if let lastUpdated = goalProvider.lastUpdated {
        debugRow("Last Updated", formatDate(lastUpdated))
      }

      if goalProvider.goals.isNotEmpty {
        Divider()
        ForEach(goalProvider.goals.prefix(5)) { goal in
          Text("- \(goal.metricName): target \(Int(goal.targetValue))")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        if goalProvider.goals.count > 5 {
          Text("... and \(goalProvider.goals.count - 5) more")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(.vertical, 16)
  }

  var subscriptionSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionHeader("Subscription")

      debugRow("Status", subscriptionProvider.isSubscribed ? "Subscribed" : "Not Subscribed")
    }
    .padding(.vertical, 16)
  }

  var unitPreferencesSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionHeader("Unit Preferences")

      debugRow("Weight", unitProvider.weightUnit.unitString)
      debugRow("Distance", unitProvider.distanceUnit.unitString)
      debugRow("Liquid", unitProvider.liquidVolumeUnit.unitString)
      debugRow("Height", unitProvider.heightUnit.unitString)
    }
    .padding(.vertical, 16)
  }

  var pendingEntriesSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionHeader("Pending Food Logs")

      debugRow("Count", "\(pendingFoodLogManager.pendingEntries.count)")

      if pendingFoodLogManager.pendingEntries.isNotEmpty {
        Divider()
        ForEach(pendingFoodLogManager.pendingEntries) { entry in
          VStack(alignment: .leading, spacing: 2) {
            Text("ID: \(entry.foodItemID.prefix(8))...")
              .font(.caption2)
              .foregroundStyle(.secondary)
            Text("Meal: \(entry.meal), Servings: \(entry.numberOfServings, specifier: "%.1f")")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .padding(.vertical, 16)
  }
}

// MARK: - Helper Views

private extension DebugDataView {

  func sectionHeader(_ title: String) -> some View {
    Text(title)
      .font(.headline)
      .bold()
      .fontDesign(.rounded)
      .foregroundStyle(.white)
  }

  func debugRow(_ label: String, _ value: String) -> some View {
    HStack {
      Text(label)
        .font(.caption2)
        .foregroundStyle(.secondary)
      Spacer()
      Text(value)
        .font(.caption2)
        .foregroundStyle(.white)
    }
  }

  func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      DebugDataView()
    }
  }
}
