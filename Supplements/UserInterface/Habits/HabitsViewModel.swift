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

    let modelContext = ModelContext(ContainerHolder.shared.container)
}

extension HabitsViewModel {

    func shouldUpdateSuggestedHabits() async -> Bool {
        await HabitsFactory.shared.shouldUpdateSuggestedHabits()
    }

    func generateProposedHabits() async -> [ProposedHabit] {
        return await HabitsFactory.shared.generateProposedHabits()
    }

    func performSave(proposedHabits: [ProposedHabit]) throws {
        for proposedHabit in proposedHabits {
            if
                let habitID = proposedHabit.habitID,
                let existingHabit = try modelContext.fetchHabit(id: habitID)
            {
                existingHabit.endDate = .now
            }

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
    }
}
