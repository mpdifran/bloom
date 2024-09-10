//
//  HabitDailyUpdateCellViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-10.
//

import SwiftUI

@MainActor
final class HabitDailyUpdateCellViewModel: ObservableObject {

    @Published var didHitGoal = 0
    @Published var dailyValue: Double = 0 {
        didSet { checkHitGoal() }
    }
    @Published var yesterdayValue: Double = 0
    @Published var hasCompletedTodayGoal = false

    private let habitModel: HabitModel

    init(habitModel: HabitModel) {
        self.habitModel = habitModel
        observeValues()
    }

    private var didSendConfetti = false
    private var didSendNotification = false

    private var observationHandler: HKObserverQueryHandle?
    private var backgroundHandler: HKBackgroundDeliveryHandle?
}

extension HabitDailyUpdateCellViewModel {

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

private extension HabitDailyUpdateCellViewModel {

    func observeValues() {
        backgroundHandler = HealthManager.shared.healthStore.enableBackgroundDelivery(
            objectTypes: habitModel.measurement.sampleTypes,
            frequency: .immediate
        )
        observationHandler = HealthManager.shared.healthStore.observeChanges(
            sampleTypes: habitModel.measurement.sampleTypes,
            startDate: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now
        ) { [weak self] in
            await self?.loadValues()
        }
    }

    func loadValues() async {
        let currentValue = await habitModel.measurement.quantity(for: .startOfDayToNow()).doubleValue(for: habitModel.measurement.unit)
        let prevValue = await habitModel.measurement.quantity(for: .yesterday()).doubleValue(for: habitModel.measurement.unit)

        await MainActor.run {
            dailyValue = currentValue
            yesterdayValue = prevValue
            let prevHasCompletedGoal = hasCompletedTodayGoal
            hasCompletedTodayGoal = dailyValue > (habitModel.value)
            checkHitGoal()

            if !prevHasCompletedGoal && hasCompletedTodayGoal {
                Task {
                    await sendHabitHitNotification()
                }
            } else if !hasCompletedTodayGoal {
                didSendNotification = false
            }
        }
    }

    func sendHabitHitNotification() async {
        if UIApplication.shared.applicationState != .active && !didSendNotification {
            await NotificationManager.shared.sendNotification(
                title: "Great Job, You Did It!",
                subtitle: "You've hit your \(habitModel.name) habit, great job!"
            )
        }

        await MainActor.run {
            didSendNotification = true
        }
    }
}
