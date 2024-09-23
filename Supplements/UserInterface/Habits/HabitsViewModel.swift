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

@MainActor
final class HabitsViewModel: ObservableObject {
    static let shared = HabitsViewModel()
}

extension HabitsViewModel {

    func shouldUpdateSuggestedHabits() async -> Bool {
        await HabitsFactory.shared.shouldUpdateSuggestedHabits()
    }

    func generateProposedHabits() async -> [ProposedHabit] {
        return await HabitsFactory.shared.generateProposedHabits()
    }
}
