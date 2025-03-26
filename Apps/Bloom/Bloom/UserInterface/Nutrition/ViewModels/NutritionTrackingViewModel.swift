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

struct DateState {
  let date: Date
  let state: FoodLogDateCell.State
}

@MainActor
final class NutritionTrackingViewModel: ObservableObject {
  static let shared = NutritionTrackingViewModel()

  @Published var date = Date.now
  @Published var suggestedMeal = FoodItemLog.Meal.breakfast
  @Published var dateStates = [DateState]()

  @Storage(key: .lastMealAutoUpdateDateKey, defaultValue: nil) var lastMealAutoUpdateDate: Date?

  private let modelContext = ModelContext(ContainerHolder.shared.container)

  private init() {
    updateMealForCurrentTime()
    Task {
      await refreshDateStates()
    }
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

  func updateNutrition(for dates: Set<Date>) async throws {
    for date in dates {
      try await HealthStoreModifier.shared.updateNutrition(for: date)
    }
    await refreshDateStates()
  }

  func refreshDateStates() async {
    let dateRange = DateRange.window(around: .now, numberOfDays: 30)
    let modelActor = FoodItemLogModelActor.standard()

    var newDateStates = [DateState]()

    await withTaskGroup(of: DateState?.self) { group in
      Calendar.current.iterate(
        dateRange: dateRange,
        by: DateComponents(day: 1)
      ) { date in
        group.addTask {
          guard let logs = try? await modelActor.fetchLogs(for: date) else { return nil }

          let validMeals: Set<FoodItemLog.Meal> = [.breakfast, .lunch, .dinner]
          let meals = logs
            .filter { validMeals.contains($0.meal) }
            .map { $0.meal }
            .asSet()

          if meals.count == validMeals.count {
            return DateState(date: date, state: .complete)
          } else {
            let percentComplete = Double(meals.count) / Double(validMeals.count)
            return DateState(date: date, state: .inProgress(percentComplete))
          }
        }
      }
      
      for await state in group {
        if let state = state {
          newDateStates.append(state)
        }
      }
    }

    self.dateStates = newDateStates
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
