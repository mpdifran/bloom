//
//  HabitsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-18.
//

import SwiftUI
import DataContainer
import TelemetryDeck

@MainActor
final class HabitsViewModel: ObservableObject {
    static let shared = HabitsViewModel()

    private init() { }
}

extension HabitsViewModel {

    func generateProposedHabits() async -> [Habit] {
        let existingHabits: [Habit]
        do {
            existingHabits = try DataFetcher.shared.fetchActiveHabits(source: .suggested)
        } catch {
            print(error)
            TelemetryDeck.errorOccurred(
                id: "HabitsViewModel.fetchActiveSuggestedHabits",
                category: .thrownException,
                message: error.localizedDescription
            )
            existingHabits = []
        }

        var newHabits = [Habit]()
        for habit in existingHabits {
            guard let newHabit = await updatedHabit(for: habit) else { continue }

            newHabits.append(newHabit)
        }

        if newHabits.isEmpty {
            if let newHabit = await suggestNewHabit() {
                newHabits.append(newHabit)
            }
        }

        return newHabits
    }
}

private extension HabitsViewModel {

    func updatedHabit(for habit: Habit) async -> Habit? {
        let targetMetric = habit.targetMetric
        let unit = habit.unit

        let habitHistory: [Habit]
        do {
            habitHistory = try DataFetcher.shared.fetchHabits(for: targetMetric, source: .suggested)
        } catch {
            print(error)
            TelemetryDeck.errorOccurred(
                id: "HabitsViewModel.fetchSuggestedHabits",
                category: .thrownException,
                message: error.localizedDescription
            )
            habitHistory = []
        }

        let lastThreeWeeksSamples = await targetMetric.fetchCollatedDailyQuantity(
            unit: unit,
            dateRange: .trailingWeeksFromNow(3)
        )
        let dailyAverage = lastThreeWeeksSamples
            .map({ $0.quantity.doubleValue(for: unit) })
            .average(keyPath: \.self)

        let passFailPercentage = goalMetPercentage(habitHistory: habitHistory, samples: lastThreeWeeksSamples)

        let currentValue = habit.value

        let newValue = [dailyAverage, currentValue].average(keyPath: \.self)

        return Habit(
            source: .suggested,
            targetMetric: targetMetric,
            value: newValue,
            unitString: unit.unitString,
            startDate: .now,
            vitalKind: habit.vitalKind, // Does this always stay the same?
            context: habit.context
        )
    }

    func goalMetPercentage(habitHistory: [Habit], samples: [DateQuantitySample]) -> Double {
        var passCount = 0
        var totalCount = 0

        for sample in samples {
            guard let habit = habitHistory.first(where: { $0.isDateWithinHabit(date: sample.date) }) else { continue }

            let unit = habit.unit
            let habitTarget = habit.quantity.doubleValue(for: unit)
            let sampleValue = sample.quantity.doubleValue(for: unit)

            if sampleValue >= habitTarget {
                passCount += 1
            }
            totalCount += 1
        }

        return Double(passCount) / Double(totalCount)
    }

    func suggestNewHabit() async -> Habit? {
        return nil
    }
}
