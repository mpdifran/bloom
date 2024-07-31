//
//  GoalsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI

final class GoalsViewModel: ObservableObject {
    static let shared = GoalsViewModel()

    @Published var goals = [GoalModel]()

    private var lastGoalCheckDate: Date? {
        didSet { UserDefaults.group.set(lastGoalCheckDate, forKey: "lastGoalCheckDate") }
    }

    private init() { 
        if let date = UserDefaults.group.object(forKey: "lastGoalCheckDate") as? Date {
            self.lastGoalCheckDate = date
        }
    }
}

extension GoalsViewModel {

    func checkForUpdateGoals() {
        let sleepVitals = VitalsViewModel.shared.sleepVitalsSummary

        let trend: GoalModel.Vital.Trend
        switch sleepVitals?.trend {
        case .increasing:
            trend = .increasing
        case .decreasing:
            trend = .decreasing
        case .noTrend:
            trend = .noTrend
        case nil:
            trend = .noTrend
        }

        let goal = GoalModel(
            title: "Get More Sunlight",
            systemImage: "sun.max.fill",
            summary: "More sun is good for your body. It also gives you Vitamin D! Aim to get 50 minutes of sunlight this week.",
            color: .orange,
            metric: .init(
                value: 300,
                measurement: .timeInDaylight
            ),
            vital: .init(
                name: "Sleep Quality",
                systemImage: "moon.zzz",
                metricValue: sleepVitals?.quality.name ?? "No Data",
                color: sleepVitals?.quality.color ?? .gray,
                trend: trend
            )
        )
        goals = [goal]
    }
}
