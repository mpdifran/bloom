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

    @MainActor @Published var goals = [GoalModel]() {
        didSet {
            do {
                let data = try JSONEncoder.main.encode(goals)
                UserDefaults.group.set(data, forKey: "GoalsViewModel.goals")
            } catch {
                print(error)
            }
        }
    }

    private init() {
        Task {
            await loadGoals()
        }
    }
}

extension GoalsViewModel {

    func loadGoals() async {
        if
            let data = UserDefaults.group.data(forKey: "GoalsViewModel.goals"),
            let goals = try? JSONDecoder.main.decode([GoalModel].self, from: data)
        {
            await MainActor.run {
                self.goals = goals
            }
        }
    }

    func checkForUpdateGoals(force: Bool = false) async {
        await loadGoals()

        if let goalDueDate = await goals.first?.dueDate {
            if goalDueDate > .now && !force {
                print("Returning early since goals are still valid")
                return
            }
        }

        guard let dueDate = Calendar.current.startOfNextWeek(for: .now) else { return }

        var goals = [GoalModel]()

        var vitalNames = [String]()
        let sortedVitals = VitalsViewModel.shared.vitals.sorted(by: { $0.score < $1.score })
        if let vital = sortedVitals.safeAccess(at: 0), let goal = await goal(for: vital, dueDate: dueDate) {
            goals.append(goal)
            vitalNames.append(vital.id.name)
        }

        if let vital = sortedVitals.safeAccess(at: 1), let goal = await goal(for: vital, dueDate: dueDate) {
            goals.append(goal)
            vitalNames.append(vital.id.name)
        }

        let newGoals = goals

        await MainActor.run {
            self.goals = newGoals
        }

        let listFormatter = ListFormatter()
        let string = listFormatter.string(from: vitalNames)

        let subtitle: String
        if let string {
            subtitle = "Check out your new goals this week targeting \(string)!"
        } else {
            subtitle = "Check out your new goals this week!"
        }

        await NotificationManager.shared.sendNotification(
            title: "New Goals Available",
            subtitle: subtitle,
            categoryID: .CategoryID.goalsMessage
        )
    }
}

private extension GoalsViewModel {

    func goal(for vital: VitalModel, dueDate: Date) async -> GoalModel? {
        switch vital.id {
        case .sleepQuality:
            return await timeInDaylightGoal(
                summary: "Your sleep scores have been a bit low lately. Try getting some more sunlight than you normally do this week!",
                vitalKind: .sleepQuality,
                dueDate: dueDate
            )
        case .activityLevel:
            return await stepGoal(
                summary: "Let's improve your activty level by incorporating more steps in your day. Walking has numerous other health benefits.",
                vitalKind: .activityLevel,
                dueDate: dueDate
            )
        case .cardioFitness:
            return await runDistanceGoal(
                summary: "Your Cardio Fitness should be your main focus. Let's focus on running more this week.",
                vitalKind: .cardioFitness,
                dueDate: dueDate
            )
        case .bodyComposition:
            return await stepGoal(
                summary: "Your body composition is out of the recommended range. A quick way to start making progess is to increase your steps.",
                vitalKind: .bodyComposition,
                dueDate: dueDate
            )
        case .mobility:
            return await walkRunDistanceGoal(
                summary: "Your mobility should be top of mind for you this week. You can improve your mobility by walking or running more!",
                vitalKind: .mobility,
                dueDate: dueDate
            )
        case .stressLevels:
            return await meditationGoal(
                summary: "Your stress levels are getting quite high. Try incorporating more meditation this week.",
                vitalKind: .stressLevels,
                dueDate: dueDate
            )
        case .nutrition:
            break
        }
        return nil
    }
}

private extension GoalsViewModel {

    func timeInDaylightGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        let average = await HealthManager.shared.fetchWeeklyAverage(
            for: .timeInDaylight,
            unit: .minute(),
            numWeeks: .numWeeksPastAverage
        )

        return GoalModel(
            title: "Get More Sunlight",
            systemImage: "sun.max.fill",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(average * .goalMultiplier, 200),
                measurement: .timeInDaylight
            ),
            vitalKind: vitalKind
        )
    }

    func walkRunDistanceGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        let average = await HealthManager.shared.fetchWeeklyAverage(
            for: .distanceWalkingRunning,
            unit: .meterUnit(with: .kilo),
            numWeeks: .numWeeksPastAverage
        )

        return GoalModel(
            title: "Increase Walking + Running Distance",
            systemImage: "figure.walk",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(average * .goalMultiplier, 1),
                measurement: .walkRunDistance
            ),
            vitalKind: vitalKind
        )
    }

    func runDistanceGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        let workouts = await HealthManager.shared.fetchWorkoutSummaries(
            activityType: .running,
            numWeeks: .numWeeksPastAverage
        )

        let average = workouts.sum(keyPath: \.distance) / Double(Int.numWeeksPastAverage)

        return GoalModel(
            title: "Run For Longer Distances",
            systemImage: "figure.run",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(average * .goalMultiplier, 2),
                measurement: .runDistance
            ),
            vitalKind: vitalKind
        )
    }

    func stepGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        let average = await HealthManager.shared.fetchWeeklyAverage(
            for: .stepCount,
            unit: .count(),
            numWeeks: .numWeeksPastAverage
        )

        return GoalModel(
            title: "Increase Step Count",
            systemImage: "figure.walk",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(average * .goalMultiplier, 1000),
                measurement: .stepCount
            ),
            vitalKind: vitalKind
        )
    }

    func meditationGoal(summary: String, vitalKind: VitalModel.Kind, dueDate: Date) async -> GoalModel {
        let average = await HealthManager.shared.fetchWeeklyAverageMeditationMinutes(numWeeks: .numWeeksPastAverage)

        return GoalModel(
            title: "Meditate More Often",
            systemImage: "figure.mind.and.body",
            summary: summary,
            dueDate: dueDate,
            metric: .init(
                value: max(average * .goalMultiplier, 10),
                measurement: .meditationMinutes
            ),
            vitalKind: vitalKind
        )
    }
}
