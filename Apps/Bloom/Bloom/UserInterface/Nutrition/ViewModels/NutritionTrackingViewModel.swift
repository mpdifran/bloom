//
//  NutritionTrackingViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-22.
//

import SwiftUI
import SwiftData
import BloomModel
import DataContainer
import TelemetryDeck
import BloomFoundation

extension String {
  static let lastMealAutoUpdateDateKey = "NutritionTrackingViewModel.lastMealAutoUpdateDate"
}

@MainActor
final class NutritionTrackingViewModel: ObservableObject {
  static let shared = NutritionTrackingViewModel()

  @Published var date = Date.now
  @Published var suggestedMeal = FoodItemLog.Meal.breakfast

  @Storage(key: .lastMealAutoUpdateDateKey, defaultValue: nil) var lastMealAutoUpdateDate: Date?

  private let modelContext = ModelContext(ContainerHolder.shared.container)

  private init() {
    updateMealForCurrentTime()
  }
}

extension NutritionTrackingViewModel {

  func updateMealForCurrentTime() {
    if let lastUpdateDate = lastMealAutoUpdateDate {
      guard Date.now.timeIntervalSince(lastUpdateDate) > 60 * 5 else {
        return
      }
    }

    date = .now
    let hour = Calendar.current.component(.hour, from: date)

    switch hour {
    case 6 ..< 11:
      suggestedMeal = .breakfast
    case 11 ..< 16:
      suggestedMeal = .lunch
    case 16 ..< 24:
      suggestedMeal = .dinner
    default:
      return
    }

    lastMealAutoUpdateDate = .now
  }

  /// Advances the suggested meal by one meal. If needed, the day will advance as well.
  func advanceTimeWindow() {
    switch suggestedMeal {
    case .breakfast:
      suggestedMeal = .lunch
    case .lunch:
      suggestedMeal = .dinner
    case .dinner:
      suggestedMeal = .snack
    case .snack:
      suggestedMeal = .breakfast
      advanceDay()
    @unknown default:
      break
    }
  }

  /// Reverses the suggested meal by one meal. If needed, the day will reverse as well.
  func reverseTimeWindow() {
    switch suggestedMeal {
    case .breakfast:
      suggestedMeal = .snack
      reverseDay()
    case .lunch:
      suggestedMeal = .breakfast
    case .dinner:
      suggestedMeal = .lunch
    case .snack:
      suggestedMeal = .dinner
    @unknown default:
      break
    }
  }

  func advanceDay() {
    date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
  }

  func reverseDay() {
    date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
  }
}

extension NutritionTrackingViewModel {

  nonisolated func reSyncNutritionToHealthKit() async throws {
    guard let earliestLog = try await earliestLogDate() else { return }

    let dateRange = DateRange(earliestLog, Date())

    await Calendar.current.asyncIterate(dateRange: dateRange, by: DateComponents(day: 1)) { date in
      do {
        try await HealthStoreModifier.shared.updateNutrition(for: date)
      } catch {
        print(error)
      }
    }
  }

  private func earliestLogDate() throws -> Date? {
    try modelContext.fetchOldestFoodItemLog()?.date
  }
}
