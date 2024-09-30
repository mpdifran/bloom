//
//  HabitsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-18.
//

import SwiftUI
import DataContainer
import TelemetryDeck
import HealthKit
import SwiftData

@MainActor
final class HabitsViewModel: ObservableObject {
    static let shared = HabitsViewModel()

    @Published var shouldUpdateSuggestedHabits = false

    private var lastHabitRefreshDate: Date? {
        didSet {
            UserDefaults.group.set(lastHabitRefreshDate, forKey: "HabitsViewModel.lastHabitRefreshDate")
            checkUpdateSuggestedHabits()
        }
    }

    let modelContext = ModelContext(ContainerHolder.shared.container)

    init() {
        if let date = UserDefaults.group.object(forKey: "HabitsViewModel.lastHabitRefreshDate") as? Date {
            lastHabitRefreshDate = date
        }
    }
}

extension HabitsViewModel {

    func checkUpdateSuggestedHabits() {
        guard let lastHabitRefreshDate else {
            shouldUpdateSuggestedHabits = true
            return
        }

        let mondayMorning = Calendar.current.mondayMorning(for: .now) ?? .distantPast

        shouldUpdateSuggestedHabits = mondayMorning > lastHabitRefreshDate
    }

    func generateProposedHabits() async -> NewHabitResult {
        await HabitsFactory.shared.generateProposedHabits()
    }

    func alternateTargetMetrics(for proposedHabit: ProposedHabit) -> [TargetMetric] {
        let alternativeTargetMetrics = proposedHabit.targetMetric.related

        guard alternativeTargetMetrics.isNotEmpty else { return [] }

        do {
            let existingTargetMetrics = try modelContext.fetchActiveHabits(isSuggested: false).map(\.targetMetric).asSet()

            return alternativeTargetMetrics.filter({ !existingTargetMetrics.contains($0) })
        } catch {
            print(error)
        }
        return []
    }

    func generateProposedHabit(
        for targetMetric: TargetMetric,
        vitalKind: VitalModel.Kind?
    ) async -> ProposedHabit {
        await HabitsFactory.shared.generateProposedHabit(
            for: targetMetric,
            vitalKind: vitalKind
        )
    }

    func performSave(proposedHabits: [ProposedHabit], proposedToDos: [ProposedToDo]) throws {
        for existingHabit in try modelContext.fetchActiveHabits(isSuggested: true) {
            existingHabit.endDate = .now
        }

        for proposedHabit in proposedHabits {
            let habit = Habit(
                targetMetric: proposedHabit.targetMetric,
                value: proposedHabit.value,
                unitString: proposedHabit.unitString,
                startDate: .now,
                isSuggested: true,
                isUserEdited: false,
                vitalKind: proposedHabit.vitalKind,
                context: proposedHabit.context
            )

            modelContext.insert(habit)
        }

        try modelContext.save()

        for proposedToDo in proposedToDos {
            ToDoManager.shared.set(proposedToDo.todoCadence, for: proposedToDo.todoKind)
        }

        lastHabitRefreshDate = .now
    }
}
