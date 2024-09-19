//
//  HabitDailyUpdateCellViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-19.
//

import SwiftUI
import DataContainer

@MainActor
final class HabitDailyUpdateCellViewModel: ObservableObject {

    @Published var dailyValue: Double = 0
    @Published var hasCompletedTodayGoal = false

    private let habit: Habit

    init(habit: Habit) {
        self.habit = habit
        observeValues()
    }

    private var observationHandler: HKObserverQueryHandle?
}

private extension HabitDailyUpdateCellViewModel {

    func observeValues() {
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

        hasCompletedTodayGoal = dailyValue >= habit.value
    }
}
