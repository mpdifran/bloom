//
//  InsightsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import Foundation

final class InsightsViewModel: ObservableObject {
    static let shared = InsightsViewModel()

    @Published var workoutSummary = [WorkoutSummary]()
    @Published var timeInDaylight = [DateQuantitySample]()

    private init() { }
}

extension InsightsViewModel {

    func loadData() async throws {
        let workoutSummary = await HealthManager.shared.fetchWorkoutSummaryLastTwoWeeks()
        let timeInDaylight = await HealthManager.shared.fetchTimeInDaylight()

        await MainActor.run {
            self.workoutSummary = workoutSummary
            self.timeInDaylight = timeInDaylight
        }
    }

//    func loadData() async throws {
//        await MainActor.run {
//            self.insights = nil
//        }
//
//        let userInfo = HealthManager.shared.userInfo
//        let supplements = ProfileViewModel.shared.userSupplements
//        let goals = ProfileViewModel.shared.userGoals
//        let learnedUserFacts = ProfileViewModel.shared.userFacts
//
//        let request = InsightsRequest(
//            userInfo: userInfo,
//            currentSupplements: supplements,
//            currentGoals: goals,
//            learnedUserFacts: learnedUserFacts
//        )
//
//        let response = try await NetworkRequester.shared.fetchInsights(request: request)
//
//        await MainActor.run {
//            self.insights = response
//        }
//    }
}
