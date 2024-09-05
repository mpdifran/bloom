//
//  GoalDetailsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-03.
//

import SwiftUI
import HealthKit
import Combine

@MainActor
final class GoalDetailsViewModel: ObservableObject {

    @Published var dailyQuantities = [DateQuantitySample]() {
        didSet {
            Task { await loadProjectedEndQuantity() }
        }
    }
    @Published var projectedEndQuantity: HKQuantity?
    @Published var goal: GoalModel
    @Published var allGoals: [GoalModel]

    @Binding var goals: [GoalModel] {
        didSet {
            goal = goals[0]
            allGoals = goals
        }
    }

    init(goals: Binding<[GoalModel]>) {
        self._goals = goals
        self.goal = goals.wrappedValue[0]
        self.allGoals = goals.wrappedValue

        observeValues()
    }

    private var observationHandler: HKObserverQueryHandle?
}

extension GoalDetailsViewModel {

    func selectGoal(at index: Int) {
        dailyQuantities = []
        projectedEndQuantity = nil
        observationHandler = nil

        goals.move(fromOffsets: [index], toOffset: 0)

        observeValues()
    }
}

private extension GoalDetailsViewModel {

    var dateRange: DateRange {
        DateRange.mondayMorningToNow()
    }

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
        let data = await goal.metric.fetchCollatedDailyQuantity(for: dateRange)

        await MainActor.run {
            self.dailyQuantities = data
        }
    }

    func loadProjectedEndQuantity() async {
        guard
            let start = Calendar.current.mondayMorning(for: .now),
            let end = Calendar.current.nextMondayMorning(for: .now)
        else { return }

        guard
            let hours = Calendar.current.dateComponents([.hour], from: start, to: .now).hour,
            let remainingHours = Calendar.current.dateComponents([.hour], from: .now, to: end).hour
        else {
            return
        }

        let quantity = await goal.metric.quantity(for: dateRange)
        let rate = quantity.doubleValue(for: goal.metric.unit) / Double(hours)
        let remainingQuantity = HKQuantity(unit: goal.metric.unit, doubleValue: rate * Double(remainingHours))

        await MainActor.run {
            self.projectedEndQuantity = quantity.sum(remainingQuantity, unit: goal.metric.unit)
        }
    }
}
