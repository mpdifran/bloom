//
//  HabitDailyUpdateCellViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-19.
//

import SwiftUI
import DataContainer
import HealthKit
import TelemetryDeck
import CoreHealth

@MainActor
final class HabitDailyUpdateCellViewModel: ObservableObject {

  @Published var dailyValue: Double = 0
  @Published var goalCompletionState: CompletionCheckmarkView.State = .unmetGoal
  @Published var shouldShowConfetti = false
  @Published var sortRank: Double = 0

  let habit: Habit

  init(habit: Habit) {
    self.habit = habit
    Task {
      await observeValues()
    }
  }

  private var observationHandler: HKObserverQueryHandle?
  private var backgroundHandler: HKBackgroundDeliveryHandle?
}

extension HabitDailyUpdateCellViewModel {

  var formatter: NumberFormatter {
    let formatter = habit.targetMetric.preferredFormatter
    formatter.roundingMode = .down
    return formatter
  }

  var formattedDailyValue: String {
    let quantity = HKQuantity(unit: habit.unit, doubleValue: dailyValue)
    return quantity.displayString(for: habit.unit, formatter: formatter)
  }

  var formattedDailyValueNoUnits: String {
    let quantity = HKQuantity(unit: habit.unit, doubleValue: dailyValue)
    return quantity.displayString(for: habit.unit, formatter: formatter, showUnits: false)
  }

  var formattedExceededDailyValue: String {
    let exceededAmount = dailyValue - habit.value
    let quantity = HKQuantity(unit: habit.unit, doubleValue: exceededAmount)
    return quantity.displayString(for: habit.unit, formatter: formatter)
  }

  var goalDifferenceSummary: String {
    let difference = habit.value - dailyValue
    let unit = habit.unit
    let formatter = habit.targetMetric.preferredFormatter

    let defaultLogic = {
      if difference > 0 {
        let formatted = HKQuantity(
          unit: unit,
          doubleValue: difference
        ).displayString(for: unit, formatter: formatter)
        return String(localized: "\(formatted) below your goal today.", comment: "Goal progress, %@ is a formatted amount such as \"200 kcal\"")
      } else if difference == 0 {
        return String(localized: "You met your goal today!", comment: "Goal progress when the goal is exactly met")
      } else {
        let formatted = HKQuantity(
          unit: unit,
          doubleValue: -difference
        ).displayString(for: unit, formatter: formatter)
        return String(localized: "\(formatted) above your goal today.", comment: "Goal progress, %@ is a formatted amount such as \"200 kcal\"")
      }
    }

    switch habit.targetMetric.measurementStyle {
    case .minimum:
      return defaultLogic()
    case .range:
      let dailyQuantity = HKQuantity(unit: habit.unit, doubleValue: dailyValue)
      if habit.quantityMeetsGoal(dailyQuantity) {
        return String(localized: "You met your goal today!", comment: "Goal progress when the goal is exactly met")
      } else {
        return defaultLogic()
      }
    @unknown default:
      fatalError("Unhandled case")
    }
  }
}

private extension HabitDailyUpdateCellViewModel {

  func observeValues() async {
    backgroundHandler = await HealthStoreFetcher.shared.enableBackgroundDelivery(
      objectTypes: habit.targetMetric.sampleTypes,
      frequency: .hourly
    )
    observationHandler = HealthManager.shared.healthStore.observeChanges(
      sampleTypes: habit.targetMetric.sampleTypes,
      startDate: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now
    ) { [weak self] in
      await self?.loadValues()
    }
  }

  func loadValues() async {
    let targetMetric = habit.targetMetric
    let dateRange = habit.timePeriod.dateRange
    let dailyQuantity = await targetMetric.fetchTotalQuantity(for: dateRange)
    dailyValue = dailyQuantity.doubleValue(for: habit.unit)

    let prevHasCompletedGoal = goalCompletionState

    if habit.quantityMeetsGoal(dailyQuantity) {
      goalCompletionState = .metGoal
    } else {
      switch habit.targetMetric.measurementStyle {
      case .minimum:
        goalCompletionState = .unmetGoal
      case .range:
        if habit.quantity.compare(dailyQuantity) == .orderedDescending {
          goalCompletionState = .unmetGoal
        } else {
          goalCompletionState = .exceededGoal
        }
      @unknown default:
        fatalError("Unknown Case")
      }
    }

    sortRank = calculateSortRank()

    if
      prevHasCompletedGoal != .metGoal &&
        goalCompletionState == .metGoal &&
        !isNotificationAlreadySentInCurrentPeriod()
    {
      let id = habit.persistentModelID
      do {
        try ContainerHolder.shared.editAndSave { context in
          let editableHabit = try context.fetchHabit(id: id)
          editableHabit?.lastNotificationDate = .now
        }

        await sendHabitHitNotification()
        shouldShowConfetti = true
      } catch {
        TelemetryDeck.errorOccurred(
          id: "HabitDailyUpdateCellViewModel.habitGoalNotification",
          category: .thrownException,
          message: error.localizedDescription
        )
        print(error)
      }
    }
  }

  func sendHabitHitNotification() async {
    guard NotificationPreferences.shared.goalAchievementsEnabled else { return }

    if UIApplication.shared.applicationState != .active {
      await NotificationManager.shared.sendNotification(
        title: String(localized: "You Did It!", comment: "Notification title when a goal is hit"),
        subtitle: String(localized: "You've hit your \(habit.targetMetric.name) goal, great job!", comment: "Notification body when a goal is hit, %@ is the goal's name")
      )
    }
  }

  func calculateSortRank() -> Double {
    // Determine the current daily quantity
    let dailyQuantity = HKQuantity(unit: habit.unit, doubleValue: dailyValue)

    // If it's met the goal, put it at the end of the list.
    if habit.quantityMeetsGoal(dailyQuantity) {
      return Double.greatestFiniteMagnitude
    }

    // If it's exceeded the goal, order it by closest to the goal.
    if dailyValue > habit.value {
      let percent = dailyValue.scaledPercent(lower: habit.value, upper: habit.value * 2)
      return 1000 + percent * 100
    }

    // If we haven't met the goal, order it by progress ascending
    let percent = dailyValue.scaledPercent(lower: 0, upper: habit.value)
    return percent * 100
  }
  
  func isNotificationAlreadySentInCurrentPeriod() -> Bool {
    guard let lastNotificationDate = habit.lastNotificationDate else {
      return false
    }
    
    let calendar = Calendar.current
    let now = Date()
    
    switch habit.timePeriod {
    case .daily:
      return calendar.isDate(lastNotificationDate, inSameDayAs: now)
    case .weekly:
      return calendar.isDate(lastNotificationDate, equalTo: now, toGranularity: .weekOfYear)
    case .monthly:
      return calendar.isDate(lastNotificationDate, equalTo: now, toGranularity: .month)
    case .yearly:
      return calendar.isDate(lastNotificationDate, equalTo: now, toGranularity: .year)
    @unknown default:
      print("Unknown time period for Goal")
      return false
    }
  }
}
