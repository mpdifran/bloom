//
//  NutritionHabitTodayWidgetViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-16.
//

import Foundation
import HealthKit
import DataContainer

extension NutritionHabitTodayWidgetView {
    @Observable @MainActor
    final class ViewModel {
        var remainingCaloriesPercent: Double?
        var remainingCalories: HKQuantity?
        var remainingProteinPercent: Double?
        var remainingProtein: HKQuantity?

        init() {
            observeValues()
        }

        private var calorieObservationHandler: HKObserverQueryHandle?
        private var proteinObservationHandler: HKObserverQueryHandle?
    }
}

extension NutritionHabitTodayWidgetView.ViewModel {

    var hasNoContent: Bool {
        remainingCalories == nil &&
        remainingProtein == nil &&
        remainingCaloriesPercent == nil &&
        remainingProteinPercent == nil
    }

    func observeValues() {
        calorieObservationHandler = HealthManager.shared.healthStore.observeChanges(
            sampleTypes: [HKQuantityType(.dietaryEnergyConsumed)],
            startDate: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now
        ) { [weak self] in
            await self?.loadCalorieValues()
        }
        proteinObservationHandler = HealthManager.shared.healthStore.observeChanges(
            sampleTypes: [HKQuantityType(.dietaryProtein)],
            startDate: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now
        ) { [weak self] in
            await self?.loadProteinValues()
        }
    }

    func loadCalorieValues() async {
        let modelActor = HabitModelActor(modelContainer: ContainerHolder.shared.container)

        do {
            guard
                let habit = try await modelActor.fetchActiveHabits(for: .calories).first
            else {
                await MainActor.run {
                    self.remainingCalories = nil
                }
                return
            }

            let quantity = await HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietaryEnergyConsumed, dateRange: .today()) ?? HKQuantity(unit: .largeCalorie(), doubleValue: 0)
            let remainingCalories = habit.quantity.subtract(quantity, unit: .largeCalorie())
            let remainingCaloriesPercent = remainingCalories.doubleValue(for: .largeCalorie()) / habit.value

            await MainActor.run {
                self.remainingCalories = remainingCalories
                self.remainingCaloriesPercent = remainingCaloriesPercent
            }
        } catch {
            print(error)
        }
    }

    func loadProteinValues() async {
        let modelActor = HabitModelActor(modelContainer: ContainerHolder.shared.container)

        do {
            guard
                let habit = try await modelActor.fetchActiveHabits(for: .proteinIntake).first
            else {
                await MainActor.run {
                    self.remainingProtein = nil
                }
                return
            }

            let quantity = await HealthStoreFetcher.shared.fetchTotalQuantity(for: .dietaryProtein, dateRange: .today()) ?? HKQuantity(unit: .gram(), doubleValue: 0)
            let remainingProtein = habit.quantity.subtract(quantity, unit: .gram())
            let remainingProteinPercent = quantity.doubleValue(for: .gram()) / habit.value

            await MainActor.run {
                self.remainingProtein = remainingProtein
                self.remainingProteinPercent = remainingProteinPercent
            }
        } catch {
            print(error)
        }
    }
}
