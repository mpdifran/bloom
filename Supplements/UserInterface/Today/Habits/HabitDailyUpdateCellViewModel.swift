//
//  HabitDailyUpdateCellViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-19.
//

import SwiftUI
import DataContainer
import HealthKit

@MainActor
final class HabitDailyUpdateCellViewModel: ObservableObject {

    @Published var dailyValue: Double = 0
    @Published var hasCompletedTodayGoal = false
    @Published var shouldShowConfetti = false

    private var lastGoalCompletionDate: Date? {
        didSet {
            UserDefaults.group.set(lastGoalCompletionDate, forKey: "HabitDailyUpdateCellViewModel.lastGoalCompletionDate")
        }
    }

    private let habit: Habit

    init(habit: Habit) {
        self.habit = habit

        if let date = UserDefaults.group.object(forKey: "HabitDailyUpdateCellViewModel.lastGoalCompletionDate") as? Date {
            self.lastGoalCompletionDate = date
        }

        observeValues()
    }

    private var observationHandler: HKObserverQueryHandle?
    private var backgroundHandler: HKBackgroundDeliveryHandle?
}

extension HabitDailyUpdateCellViewModel {

    var formattedDailyValue: String {
        let quantity = HKQuantity(unit: habit.unit, doubleValue: dailyValue)
        return quantity.displayString(for: habit.unit, formatter: habit.targetMetric.preferredFormatter)
    }
}

private extension HabitDailyUpdateCellViewModel {

    func observeValues() {
        backgroundHandler = HealthManager.shared.enableBackgroundDelivery(
            objectTypes: habit.targetMetric.sampleTypes,
            frequency: .immediate
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
        let currentValue = Task.detached(priority: .userInitiated) {
            await targetMetric.fetchTotalQuantity(for: .startOfDayToNow())
        }
        dailyValue = await currentValue.value.doubleValue(for: habit.unit)

        let prevHasCompletedGoal = hasCompletedTodayGoal
        hasCompletedTodayGoal = dailyValue >= habit.value

        if !prevHasCompletedGoal && hasCompletedTodayGoal {
            await sendHabitHitNotification()
            lastGoalCompletionDate = .now
            shouldShowConfetti = true
        }
    }

    func sendHabitHitNotification() async {
        if let lastGoalCompletionDate {
            if Calendar.current.isDateInToday(lastGoalCompletionDate) {
                return
            }
        }

        if UIApplication.shared.applicationState != .active {
            await NotificationManager.shared.sendNotification(
                title: "You Did It!",
                subtitle: "You've hit your \(habit.targetMetric.name) goal, great job!"
            )
        }
    }
}
