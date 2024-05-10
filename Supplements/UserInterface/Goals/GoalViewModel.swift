//
//  GoalViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import Foundation

final class GoalViewModel: ObservableObject {
    static let shared = GoalViewModel()

    @Published private(set) var goals = [GoalModel]()
    @Published private(set) var selectedGoals = [GoalModel]()

    private init() { }
}

extension GoalViewModel {

    func loadGoals() async throws {
        self.goals = try await NetworkRequester.shared.fetchGoals()
    }

    func isGoalSelected(_ goal: GoalModel) -> Bool {
        selectedGoals.contains(goal)
    }

    func toggleSelect(goal: GoalModel) {
        if isGoalSelected(goal) {
            selectedGoals.removeAll(where: { $0 == goal })
        } else {
            selectedGoals.append(goal)
        }
    }
}
