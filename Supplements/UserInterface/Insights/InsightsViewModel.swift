//
//  InsightsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import Foundation

final class InsightsViewModel: ObservableObject {

    @Published var insights: InsightsResponse?
}

extension InsightsViewModel {

    func loadData() async throws {
        let userInfo = HealthManager.shared.userInfo
        let supplements = SupplementViewModel.shared.selectedSupplements
        let goals = GoalViewModel.shared.selectedGoals
        let learnedUserFacts = ChatViewModel.shared.learnedUserFacts

        let request = InsightsRequest(
            userInfo: userInfo,
            currentSupplements: supplements,
            currentGoals: goals,
            learnedUserFacts: learnedUserFacts
        )

        let response = try await NetworkRequester.shared.fetchInsights(request: request)

        await MainActor.run {
            self.insights = response
        }
    }
}
