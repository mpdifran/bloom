//
//  GoalViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI

final class GoalViewModel: ObservableObject {
    static let shared = GoalViewModel()

    @Published private(set) var goals = [GoalModel]()
    @Published private(set) var selectedGoals = [String]() {
        didSet {
            UserDefaults.standard.setValue(selectedGoals, forKey: "selectedGoals")
        }
    }

    private init() { 
        if let existingGoals = UserDefaults.standard.value(forKey: "selectedGoals") as? [String] {
            self.selectedGoals = existingGoals
        }
    }
}

extension GoalViewModel {

    func loadGoals() async throws {
        let goals = try await NetworkRequester.shared.fetchGoals()

        await MainActor.run {
            self.goals = goals
        }
    }

    func isGoalSelected(_ goal: GoalModel) -> Bool {
        selectedGoals.contains(goal.id)
    }

    func toggleSelect(goal: GoalModel) {
        if isGoalSelected(goal) {
            selectedGoals.removeAll(where: { $0 == goal.id })
        } else {
            selectedGoals.append(goal.id)
        }
    }
}
