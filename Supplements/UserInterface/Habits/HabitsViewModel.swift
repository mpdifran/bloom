//
//  HabitsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-18.
//

import SwiftUI
import DataContainer
import TelemetryDeck
import HealthKit

final actor HabitsViewModel: ObservableObject {
    static let shared = HabitsViewModel()

    private init() { }
}

extension HabitsViewModel {

    func shouldUpdateSuggestedHabits() -> Bool {
        let mondayMorning = Calendar.current.mondayMorning(for: .now) ?? .distantPast
        let habits = (try? DataFetcher.shared.fetchActiveHabits(isSuggested: true)) ?? []

        return habits.isEmpty || habits.contains(where: { mondayMorning > $0.startDate })
    }

    func generateProposedHabits() async -> [ProposedHabit] {
        let existingHabits: [Habit]
        do {
            existingHabits = try DataFetcher.shared.fetchActiveHabits(isSuggested: true)
        } catch {
            print(error)
            TelemetryDeck.errorOccurred(
                id: "HabitsViewModel.fetchActiveSuggestedHabits",
                category: .thrownException,
                message: error.localizedDescription
            )
            existingHabits = []
        }

        var newHabits = [ProposedHabit]()
        for habit in existingHabits {
            guard let newHabit = await updatedHabit(for: habit) else { continue }

            newHabits.append(newHabit)
        }

        if newHabits.isEmpty {
            await VitalsViewModel.shared.forceFetchVitals()
            let sortedVitals = VitalsViewModel.shared.vitals.sorted(by: { $0.score < $1.score })

            if
                let targetVital = sortedVitals.safeAccess(at: 0),
                let newHabit = await suggestNewHabit(for: targetVital)
            {
                newHabits.append(newHabit)
            }
        }

        return newHabits
    }
}

private extension HabitsViewModel {

    func updatedHabit(for habit: Habit) async -> ProposedHabit? {
        let targetMetric = habit.targetMetric
        let unit = habit.unit

        let habitHistory: [Habit]
        do {
            habitHistory = try DataFetcher.shared.fetchHabits(for: targetMetric, isSuggested: true)
        } catch {
            print(error)
            TelemetryDeck.errorOccurred(
                id: "HabitsViewModel.fetchSuggestedHabits",
                category: .thrownException,
                message: error.localizedDescription
            )
            habitHistory = []
        }

        // Calcualte changes to new habit target.
        let habitTargetValue = habit.quantity.doubleValue(for: unit)

        let lastTwoWeeksSamples = await targetMetric.fetchCollatedDailyQuantity(
            unit: unit,
            dateRange: .trailingWeeksFromNow(2)
        )
        let dailyAverage = lastTwoWeeksSamples
            .map({ $0.quantity.doubleValue(for: unit) })
            .average(keyPath: \.self)

        let passFailPercentage = goalMetPercentage(habitHistory: habitHistory, samples: lastTwoWeeksSamples)
        let percentageRelativeToHabitValue = (dailyAverage - habitTargetValue) / habitTargetValue

        var newHabitTargetValue: Double
        if passFailPercentage > 0.9 {
            // We can increase the goal by a bit.
            let percentageIncrease = percentageRelativeToHabitValue > 0.15 ? 0.1 : 0.05
            newHabitTargetValue = habitTargetValue * (1 + percentageIncrease)
        } else if passFailPercentage < 0.5 {
            // We need to lower the goal.
            let percentageDecrease = percentageRelativeToHabitValue < -0.15 ? -0.1 : -0.05
            newHabitTargetValue = habitTargetValue * (1 + percentageDecrease)
        } else {
            // Maintain the goal for some more time.
            newHabitTargetValue = habitTargetValue
        }

        // Check the ideal range
        if let idealRange = targetMetric.idealRange {
            let targetQuantity = HKQuantity(unit: unit, doubleValue: newHabitTargetValue)

            if idealRange.upper.compare(targetQuantity) == .orderedAscending {
                newHabitTargetValue = idealRange.upperDoubleValue(for: unit)
            }
        }

        return ProposedHabit(
            targetMetric: targetMetric,
            value: newHabitTargetValue,
            unitString: unit.unitString,
            vitalKind: habit.vitalKind,
            context: habit.context
        )
    }

    func goalMetPercentage(habitHistory: [Habit], samples: [DateQuantitySample]) -> Double {
        var passCount = 0
        var totalCount = 0

        for sample in samples {
            guard let habit = habitHistory.first(where: { $0.isDateWithinHabit(date: sample.date) }) else { continue }

            let unit = habit.unit
            let habitTarget = habit.quantity.doubleValue(for: unit)
            let sampleValue = sample.quantity.doubleValue(for: unit)

            if sampleValue >= habitTarget {
                passCount += 1
            }
            totalCount += 1
        }

        return Double(passCount) / Double(totalCount)
    }

    func suggestNewHabit(for vital: VitalModel) async -> ProposedHabit? {
        switch vital.id {
        case .cardioFitness:
            return await createHabit(
                targetMetric: .walkingRunningDistance,
                unit: .meterUnit(with: .kilo),
                vitalKind: vital.id,
                context: ""
            )
        case .sleepQuality:
            return await createHabit(
                targetMetric: .timeInDaylight,
                unit: .minute(),
                vitalKind: vital.id,
                context: ""
            )
        case .activityLevel:
            return await createHabit(
                targetMetric: .stepCount,
                unit: .count(),
                vitalKind: vital.id,
                context: ""
            )
        case .stressLevels:
            return await createHabit(
                targetMetric: .timeInDaylight,
                unit: .minute(),
                vitalKind: vital.id,
                context: ""
            )
        case .nutrition:
            return await createHabit(
                targetMetric: .waterIntake,
                unit: .literUnit(with: .milli),
                vitalKind: vital.id,
                context: ""
            )
        case .exerciseEffectiveness:
            return await createHabit(
                targetMetric: .walkingRunningDistance,
                unit: .meterUnit(with: .kilo),
                vitalKind: vital.id,
                context: ""
            )
        case .bowelMovements:
            return await createHabit(
                targetMetric: .waterIntake,
                unit: .literUnit(with: .milli),
                vitalKind: vital.id,
                context: ""
            )
        case .bodyComposition, .cycleTracking:
            return nil
        @unknown default:
            fatalError("Unknown VitalModel.Kind case")
        }
    }
}

private extension HabitsViewModel {

    func createHabit(
        targetMetric: TargetMetric,
        unit: HKUnit,
        vitalKind: VitalModel.Kind,
        context: String
    ) async -> ProposedHabit {
        let average = await targetMetric.fetchDailyAverage(unit: unit, dateRange: .trailingWeeksFromNow(3)).doubleValue(for: unit)
        let value: Double
        if let min = TargetMetric.stepCount.minHabitTarget?.doubleValue(for: unit) {
            value = max(min, average)
        } else {
            value = average
        }
        return ProposedHabit(
            targetMetric: targetMetric,
            value: value,
            unitString: unit.unitString,
            vitalKind: vitalKind,
            context: context
        )
    }
}
