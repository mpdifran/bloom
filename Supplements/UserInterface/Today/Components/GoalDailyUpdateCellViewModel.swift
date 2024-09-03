//
//  GoalDailyUpdateCellViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-03.
//

import Foundation

@MainActor
final class GoalDailyUpdateCellViewModel: ObservableObject {
    let goal: GoalModel

    @Published var dailyValue: Double = 0
    @Published var hasCompletedTodayGoal = false

    init(goal: GoalModel) {
        self.goal = goal
        observeValues()
    }

    private var observationHandler: HKObserverQueryHandle?
}

private extension GoalDailyUpdateCellViewModel {

    func observeValues() {
        observationHandler = HealthManager.shared.healthStore.observeChanges(
            sampleTypes: goal.metric.measurement.sampleTypes,
            dateRange: .mondayMorningToNow(),
            frequency: .immediate
        ) { [weak self] in
            await self?.loadValues()
        }
    }

    func loadValues() async {
        let currentValue = await goal.metric.quantity(for: .startOfDayToNow()).doubleValue(for: goal.metric.unit)

        await MainActor.run {
            dailyValue = currentValue
            if !goal.metric.measurement.isDecrease {
                hasCompletedTodayGoal = dailyValue > (goal.metric.value / 7)
            }
        }
    }
}
