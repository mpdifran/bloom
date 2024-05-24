//
//  InsightsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import Foundation

final class InsightsViewModel: ObservableObject {
    static let shared = InsightsViewModel()

    @Published var insights: InsightsResponse?

    private init() { }
}

extension InsightsViewModel {

    func loadData() async throws {
        let userInfo = HealthManager.shared.userInfo
        let supplements = ProfileViewModel.shared.userSupplements
        let goals = ProfileViewModel.shared.userGoals
        let learnedUserFacts = ProfileViewModel.shared.userFacts

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
