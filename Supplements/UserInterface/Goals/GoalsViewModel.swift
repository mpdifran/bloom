//
//  GoalsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI

private extension Int {
    static let numWeeksPastAverage: Int = 6
}

private extension Double {
    static let goalMultiplier: Double = 1.3
}

final actor GoalsViewModel: ObservableObject {
    static let shared = GoalsViewModel()

    @MainActor @Published var goals = [GoalModel]()

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

    func checkForUpdateGoals(force: Bool = false) async {
        if let lastGoalCheckDate {
            if !force {
                if Calendar.current.dateComponents([.day], from: lastGoalCheckDate, to: .now).day ?? 0 < 6 {
                    print("Returning early since goals were last updated \(lastGoalCheckDate)")
                    return
                }
            }
        }

        var goals = [GoalModel]()

        let targetVital = VitalsViewModel.shared.vitals.sorted(by: { $0.score < $1.score }).first

        switch targetVital?.id {
        case .sleepQuality:
            goals.append(
                await timeInDaylightGoal(
                    summary: "Your sleep scores have been a bit low lately. Try getting some more sunlight than you normally do this week!",
                    vitalKind: .sleepQuality
                )
            )
        case .activityLevel:
            goals.append(
                await stepGoal(
                    summary: "Let's improve your activty level by incorporating more steps in your day. Walking has numerous other health benefits.",
                    vitalKind: .activityLevel
                )
            )
        case .cardioFitness:
            goals.append(
                await runDistanceGoal(
                    summary: "Your Cardio Fitness should be your main focus. Let's focus on running more this week.",
                    vitalKind: .cardioFitness
                )
            )
        case .bodyComposition:
            goals.append(
                await stepGoal(
                    summary: "Your body composition is out of the recommended range. A quick way to start making progess is to increase your steps.",
                    vitalKind: .bodyComposition
                )
            )
        case .mobility:
            goals.append(
                await walkRunDistanceGoal(
                    summary: "Your mobility should be top of mind for you this week. You can improve your mobility by walking or running more!",
                    vitalKind: .mobility
                )
            )
        case .stressLevels:
            goals.append(
                await meditationGoal(
                    summary: "Your stress levels are getting quite high. Try incorporating more meditation this week.",
                    vitalKind: .stressLevels
                )
            )
        case nil:
            break
        }

        let newGoals = goals

        await MainActor.run {
            self.goals = newGoals
        }
    }
}

private extension GoalsViewModel {

    func timeInDaylightGoal(summary: String, vitalKind: VitalModel.Kind) async -> GoalModel {
        let average = await HealthManager.shared.fetchWeeklyAverage(
            for: .timeInDaylight,
            unit: .minute(),
            numWeeks: .numWeeksPastAverage
        )

        return GoalModel(
            title: "Get More Sunlight",
            systemImage: "sun.max.fill",
            summary: summary,
            color: .orange,
            metric: .init(
                value: max(average * .goalMultiplier, 600),
                measurement: .timeInDaylight
            ),
            vitalKind: vitalKind
        )
    }

    func walkRunDistanceGoal(summary: String, vitalKind: VitalModel.Kind) async -> GoalModel {
        let average = await HealthManager.shared.fetchWeeklyAverage(
            for: .distanceWalkingRunning,
            unit: .meterUnit(with: .kilo),
            numWeeks: .numWeeksPastAverage
        )

        return GoalModel(
            title: "Increase Walking + Running Distance",
            systemImage: "figure.walk",
            summary: summary,
            color: .blue,
            metric: .init(
                value: max(average * .goalMultiplier, 2),
                measurement: .walkRunDistance
            ),
            vitalKind: vitalKind
        )
    }

    func runDistanceGoal(summary: String, vitalKind: VitalModel.Kind) async -> GoalModel {
        let workouts = await HealthManager.shared.fetchWorkoutSummaries(
            activityType: .running,
            numWeeks: .numWeeksPastAverage
        )

        let average = workouts.sum(keyPath: \.distance) / Double(Int.numWeeksPastAverage)

        return GoalModel(
            title: "Run For Longer Distances",
            systemImage: "figure.run",
            summary: summary,
            color: .green,
            metric: .init(
                value: max(average * .goalMultiplier, 5),
                measurement: .runDistance
            ),
            vitalKind: vitalKind
        )
    }

    func stepGoal(summary: String, vitalKind: VitalModel.Kind) async -> GoalModel {
        let average = await HealthManager.shared.fetchWeeklyAverage(
            for: .stepCount,
            unit: .count(),
            numWeeks: .numWeeksPastAverage
        )

        return GoalModel(
            title: "Increase Step Count",
            systemImage: "figure.walk",
            summary: summary,
            color: .blue,
            metric: .init(
                value: max(average * .goalMultiplier, 1000),
                measurement: .stepCount
            ),
            vitalKind: vitalKind
        )
    }

    func meditationGoal(summary: String, vitalKind: VitalModel.Kind) async -> GoalModel {
        let average = await HealthManager.shared.fetchWeeklyAverageMeditationMinutes(numWeeks: .numWeeksPastAverage)

        return GoalModel(
            title: "Meditate More Often",
            systemImage: "figure.mind.and.body",
            summary: summary,
            color: .remSleep,
            metric: .init(
                value: max(average * .goalMultiplier, 14),
                measurement: .meditationMinutes
            ),
            vitalKind: vitalKind
        )
    }
}
