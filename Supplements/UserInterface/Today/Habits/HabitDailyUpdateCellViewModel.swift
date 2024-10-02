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

@MainActor
final class HabitDailyUpdateCellViewModel: ObservableObject {

    @Published var dailyValue: Double = 0
    @Published var hasCompletedTodayGoal = false
    @Published var shouldShowConfetti = false

    private let habit: Habit

    init(habit: Habit) {
        self.habit = habit
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
        let currentValue = Task.detached(priority: .userInitiated) {
            await targetMetric.fetchTotalQuantity(for: .startOfDayToNow())
        }
        let dailyQuantity = await currentValue.value
        dailyValue = dailyQuantity.doubleValue(for: habit.unit)

        let prevHasCompletedGoal = hasCompletedTodayGoal
        hasCompletedTodayGoal = habit.quantityMeetsGoal(dailyQuantity)

        if
            !prevHasCompletedGoal &&
            hasCompletedTodayGoal &&
            !Calendar.current.isDateInToday(habit.lastNotificationDate ?? .distantPast)
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
        if UIApplication.shared.applicationState != .active {
            await NotificationManager.shared.sendNotification(
                title: "You Did It!",
                subtitle: "You've hit your \(habit.targetMetric.name) goal, great job!"
            )
        }
    }
}
