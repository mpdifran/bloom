//
//  HabitDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-20.
//

import SwiftUI
import DataContainer
import HealthKit
import SwiftData

struct HabitDetailsView: View {
    let habit: Habit

    @State private var allSamplesTwelveWeeks = [DateQuantitySample]()
    @State private var weekQuantitySamples = [WeekQuantitySamples]() {
        didSet {
            Task { await loadHabitGridModel() }
        }
    }
    @State private var dayStats = [Calendar.Weekday : Int]()
    @State private var habitGridModel = HabitGridModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack {
                    HStack {
                        Image(systemName: habit.targetMetric.systemImage)
                            .font(.largeTitle)
                            .foregroundStyle(.tint)

                        Text(habit.targetMetric.name)
                            .font(.title3)
                            .bold()

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text(habit.displayQuantity)
                                .font(.title3)
                                .bold()
                                .fontDesign(.rounded)
                            Text("Goal")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    .padding()

                    HabitGrid(model: habitGridModel)
                }
                .padding(.bottom)

                statsSection
                    .padding(.horizontal)
            }
        }
        .tint(habit.targetMetric.color)
        .navigationTitle("Habit Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadGoalHistory()
        }
    }
}

private extension HabitDetailsView {

    var average: Double {
        allSamplesTwelveWeeks.map({ $0.quantity.doubleValue(for: habit.unit) }).average(keyPath: \.self)
    }

    var statsSection: some View {
        VStack(alignment: .leading) {
            Text("Over Last 12 Weeks")
                .font(.headline)
                .bold()

            LabeledContent("Daily Average") {
                Text("\(average.format(using: habit.targetMetric.preferredFormatter)) \(habit.unit.unitString)")
                    .fontDesign(.rounded)
                    .bold()
                    .foregroundStyle(habit.targetMetric.color)
            }
            .frame(height: 44)

            if let bestDay = dayStats.max(by: { $0.value < $1.value })?.key.name {
                Divider()

                LabeledContent("Best Day") {
                    Text(bestDay)
                        .fontDesign(.rounded)
                        .bold()
                        .foregroundStyle(habit.targetMetric.color)
                }
                .frame(height: 44)
            }

            if let worstDay = dayStats.min(by: { $0.value < $1.value })?.key.name {
                Divider()

                LabeledContent("Worst Day") {
                    Text(worstDay)
                        .fontDesign(.rounded)
                        .bold()
                        .foregroundStyle(habit.targetMetric.color)
                }
                .frame(height: 44)
            }
        }
        .cardContainer(fill: .background.secondary)
    }
}

private extension HabitDetailsView {

    func loadHabitGridModel() async {
        let targetMetric = habit.targetMetric

        Task.detached {
            let container = await ContainerHolder.shared.container
            let context = ModelContext(container)

            let habitHistory: [Habit]
            let rawTargetMetric = targetMetric.rawValue
            do {
                habitHistory = try context.fetch(
                    FetchDescriptor<Habit>(
                        predicate: #Predicate<Habit> { model in
                            model.rawTargetMetric == rawTargetMetric
                        },
                        sortBy: [SortDescriptor(\Habit.startDate)]
                    )
                )
            } catch {
                print(error)
                return
            }

            let oldestHabit = habitHistory.first

            var weeks = await weekQuantitySamples.map { weekSamples in
                let todayIndex = weekSamples.samples.firstIndex(where: { Calendar.current.isDateInToday($0.date) })

                let isCompleteArray = weekSamples.samples.map { sample in
                    let referenceHabit: Habit
                    if let habit = habitHistory.first(where: { $0.isDateWithinHabit(date: sample.date) }) {
                        referenceHabit = habit
                    } else if let oldestHabit, sample.date < oldestHabit.startDate {
                        referenceHabit = oldestHabit
                    } else {
                        return false
                    }
                    return referenceHabit.quantityExceedsGoal(sample.quantity)
                }

                return HabitGridModel.Week(
                    id: weekSamples.id,
                    isComplete: isCompleteArray,
                    todayIndex: todayIndex
                )
            }

            if weeks.count < 30 {
                var earliestId = weeks.first?.id ?? 0

                let remainingAdditions = 30 - weeks.count

                for _ in 0 ..< remainingAdditions {
                    earliestId -= 1
                    let week = HabitGridModel.Week(id: earliestId, isComplete: Array(repeating: false, count: 7))
                    weeks.insert(week, at: 0)
                }
            }

            let model = HabitGridModel(weeks: weeks)

            await MainActor.run {
                self.habitGridModel = model
            }
        }
    }

    func loadGoalHistory() async {
        let twelveWeeksSamples = await habit.targetMetric.fetchCollatedDailyQuantity(
            unit: habit.unit,
            dateRange: .trailingWeeksFromNow(12)
        )
        let samples = await habit.targetMetric.fetchCollatedDailyQuantity(
            unit: habit.unit,
            dateRange: .trailingWeeksFromNow(30)
        )

        let groupedByWeekSamples = samples.grouped { sample in
            Calendar.current.weekOfYear(for: sample.date) ?? -1
        }

        let weekSamples = groupedByWeekSamples.compactMap { (key, samples) -> WeekQuantitySamples? in
            guard
                let sample = samples.first,
                key >= 0,
                let referenceDate = Calendar.current.startOfWeek(for: sample.date)
            else { return nil }

            return WeekQuantitySamples(
                id: key,
                referenceDate: referenceDate,
                samples: samples
            )
        }.sorted(keyPath: \.referenceDate)

        var stats = [Calendar.Weekday : Int]()
        for sample in twelveWeeksSamples {
            guard let weekday = Calendar.current.weekday(for: sample.date) else { continue }

            if habit.quantityExceedsGoal(sample.quantity) {
                stats[weekday, default: 0] += 1
            }
        }

        let statsConstant = stats

        await MainActor.run {
            self.allSamplesTwelveWeeks = twelveWeeksSamples
            self.weekQuantitySamples = weekSamples
            self.dayStats = statsConstant
        }
    }
}

struct WeekQuantitySamples: Identifiable {
    let id: Int
    let referenceDate: Date
    let samples: [DateQuantitySample]
}

#Preview {
    NavigationStack {
        HabitDetailsView(
            habit: .init(
                targetMetric: .waterIntake,
                value: 1500,
                unitString: HKUnit.literUnit(with: .milli).unitString,
                startDate: .now,
                isSuggested: true,
                isUserEdited: false,
                vitalKind: .nutrition
            )
        )
    }
}
