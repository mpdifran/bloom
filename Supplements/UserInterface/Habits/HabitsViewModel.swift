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

final class HabitsViewModel: ObservableObject {
    static let shared = HabitsViewModel()

    private let dataFetcher = DataFetcher()
}

extension HabitsViewModel {

    func deleteNoneHabits() {
        Task.detached {
            let dataFetcher = DataFetcher()
            do {
                let suggestedHabits = try dataFetcher.fetchHabits(for: .none, isSuggested: true)
                let userHabits = try dataFetcher.fetchHabits(for: .none, isSuggested: false)
                let combined = suggestedHabits + userHabits

                guard combined.isNotEmpty else { return }

                for habit in combined {
                    dataFetcher.context.delete(habit)
                }

                try dataFetcher.context.save()
            } catch {
                print(error)
            }
        }
    }

    func shouldUpdateSuggestedHabits() -> Bool {
        let mondayMorning = Calendar.current.mondayMorning(for: .now) ?? .distantPast
        let habits = (try? dataFetcher.fetchActiveHabits(isSuggested: true)) ?? []

        return habits.isEmpty || habits.contains(where: { mondayMorning > $0.startDate })
    }

    func generateProposedHabits() async -> [ProposedHabit] {
        let existingHabits: [Habit]
        do {
            existingHabits = try dataFetcher.fetchActiveHabits(isSuggested: true)
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
            habitHistory = try dataFetcher.fetchHabits(for: targetMetric, isSuggested: true)
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

        let habitGoalStatistics = calculateHabitGoalStatistics(habitHistory: habitHistory, samples: lastTwoWeeksSamples)

        var newHabitTargetValue: Double
        if habitGoalStatistics.missedGoalCountPercentage > 0.4 {
            // decrease target
            let averagePercentMissedGoalBy = habitGoalStatistics.averagePercentMissedGoalBy
            newHabitTargetValue = habitTargetValue * (1 - (averagePercentMissedGoalBy / 2))
        } else if habitGoalStatistics.missedGoalSamples.count < 3 {
            // increase target
            let averagePercentExceededGoalBy = habitGoalStatistics.averagePercentExceededGoalBy
            newHabitTargetValue = habitTargetValue * (1 + (averagePercentExceededGoalBy / 2))
        } else {
            // keep target the same
            newHabitTargetValue = habitTargetValue
        }

        // Check the ideal range
        if let idealRange = targetMetric.idealRange {
            let targetQuantity = HKQuantity(unit: unit, doubleValue: newHabitTargetValue)

            if idealRange.upper.compare(targetQuantity) == .orderedAscending {
                newHabitTargetValue = idealRange.upperDoubleValue(for: unit)
            }
        }

        let previousValue = habitHistory.last?.quantity.doubleValue(for: unit)

        if habit.isUserEdited {
            return ProposedHabit(
                targetMetric: targetMetric,
                value: habitTargetValue,
                suggestedValue: newHabitTargetValue,
                previousValue: nil,
                unitString: unit.unitString,
                vitalKind: habit.vitalKind,
                context: habit.context,
                hasUserEdited: true
            )
        } else {
            return ProposedHabit(
                targetMetric: targetMetric,
                value: newHabitTargetValue,
                suggestedValue: newHabitTargetValue,
                previousValue: previousValue,
                unitString: unit.unitString,
                vitalKind: habit.vitalKind,
                context: habit.context,
                hasUserEdited: false
            )
        }
    }

    func calculateHabitGoalStatistics(
        habitHistory: [Habit],
        samples: [DateQuantitySample]
    ) -> HabitGoalStatistics {

        var metGoalSamples = [HabitGoalStatistics.HabitSamplePair]()
        var missedGoalSamples = [HabitGoalStatistics.HabitSamplePair]()

        for sample in samples {
            guard let habit = habitHistory.first(where: { $0.isDateWithinHabit(date: sample.date) }) else { continue }

            let unit = habit.unit
            let habitTarget = habit.quantity.doubleValue(for: unit)
            let sampleValue = sample.quantity.doubleValue(for: unit)

            if sampleValue >= (habitTarget * 0.95) { // 5% for grace around meeting goals
                metGoalSamples.append(
                    .init(habit: habit, sample: sample)
                )
            } else {
                missedGoalSamples.append(
                    .init(habit: habit, sample: sample)
                )
            }
        }

        return HabitGoalStatistics(
            metGoalSamples: metGoalSamples,
            missedGoalSamples: missedGoalSamples
        )
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
        if let min = targetMetric.minHabitTarget?.doubleValue(for: unit) {
            value = max(min, average)
        } else {
            value = average
        }
        return ProposedHabit(
            targetMetric: targetMetric,
            value: value,
            suggestedValue: value,
            previousValue: nil,
            unitString: unit.unitString,
            vitalKind: vitalKind,
            context: context,
            hasUserEdited: false
        )
    }
}
