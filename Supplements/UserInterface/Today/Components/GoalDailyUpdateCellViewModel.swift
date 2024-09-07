//
//  GoalDailyUpdateCellViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-03.
//

import UIKit

@MainActor
final class GoalDailyUpdateCellViewModel: ObservableObject {
    let goal: GoalModel

    @Published var didHitGoal = 0
    var didSendConfetti = false
    var didSendNotification = false
    @Published var dailyValue: Double = 0 {
        didSet { checkHitGoal() }
    }
    @Published var yesterdayValue: Double = 0
    @Published var hasCompletedTodayGoal = false

    init(goal: GoalModel) {
        self.goal = goal
        observeValues()
    }

    private var observationHandler: HKObserverQueryHandle?
    private var backgroundHandler: HKBackgroundDeliveryHandle?
}

extension GoalDailyUpdateCellViewModel {

    func checkHitGoal() {
        if UIApplication.shared.applicationState == .active {
            if hasCompletedTodayGoal && !didSendConfetti {
                didHitGoal += 1
                didSendConfetti = true
            }
        }
        if !hasCompletedTodayGoal {
            didSendConfetti = false
        }
    }
}

private extension GoalDailyUpdateCellViewModel {

    func observeValues() {
        backgroundHandler = HealthManager.shared.healthStore.enableBackgroundDelivery(
            objectTypes: goal.metric.measurement.sampleTypes,
            frequency: .immediate
        )
        observationHandler = HealthManager.shared.healthStore.observeChanges(
            sampleTypes: goal.metric.measurement.sampleTypes,
            dateRange: .mondayMorningToNow(),
            frequency: .immediate
        ) { [weak self] in
            await self?.loadValues()
        }
    }

    func loadValues() async {
        let currentValue = await goal.metric.quantity(for: .startOfDayToNow()).doubleValue(for: goal.metric.unit)
        let prevValue = await goal.metric.quantity(for: .yesterday()).doubleValue(for: goal.metric.unit)

        await MainActor.run {
            dailyValue = currentValue
            yesterdayValue = prevValue
            let prevHasCompletedGoal = hasCompletedTodayGoal
            if !goal.metric.measurement.isDecrease {
                hasCompletedTodayGoal = dailyValue > (goal.metric.value / 7)
            } else {
                hasCompletedTodayGoal = false
            }
            
            checkHitGoal()

            if !prevHasCompletedGoal && hasCompletedTodayGoal {
                Task {
                    await sendGoalHitNotification()
                }
            } else if !hasCompletedTodayGoal {
                didSendNotification = false
            }
        }
    }

    func sendGoalHitNotification() async {
        if UIApplication.shared.applicationState != .active && !didSendNotification {
            await NotificationManager.shared.sendNotification(
                title: "You Did It!",
                subtitle: "You've hit your \(goal.title) goal, great job!"
            )
        }

        await MainActor.run {
            didSendNotification = true
        }
    }
}
