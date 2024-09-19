//
//  HabitDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-11.
//

import SwiftUI
import HealthKit

struct HabitDetailsView: View {
    let habit: HabitModel

    @State private var allSamplesEightWeeks = [DateQuantitySample]()
    @State private var weekQuantitySamples = [WeekQuantitySamples]()
    @State private var dayStats = [Calendar.Weekday : Int]()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack {
                    HStack {
                        Image(systemName: habit.systemImage)
                            .font(.largeTitle)
                            .foregroundStyle(.tint)

                        Text(habit.name)
                            .font(.title3)
                            .bold()

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("\(habit.value.format(using: .oneDecimalPlace)) \(habit.unit.unitString)")
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
        .tint(habit.measurement.color)
        .navigationTitle("Habit Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadGoalHistory()
        }
    }
}

private extension HabitDetailsView {

    var average: Double {
        allSamplesEightWeeks.map({ $0.quantity.doubleValue(for: habit.unit) }).average(keyPath: \.self)
    }

    var statsSection: some View {
        VStack(alignment: .leading) {
            Text("Over Last 8 Weeks")
                .font(.headline)
                .bold()

            LabeledContent("Daily Average") {
                Text("\(average.format(using: .oneDecimalPlace)) \(habit.unit.unitString)")
                    .fontDesign(.rounded)
                    .bold()
                    .foregroundStyle(habit.color)
            }
            .frame(height: 44)

            if let bestDay = dayStats.max(by: { $0.value < $1.value })?.key.name {
                Divider()

                LabeledContent("Best Day") {
                    Text(bestDay)
                        .fontDesign(.rounded)
                        .bold()
                        .foregroundStyle(habit.color)
                }
                .frame(height: 44)
            }

            if let worstDay = dayStats.min(by: { $0.value < $1.value })?.key.name {
                Divider()

                LabeledContent("Worst Day") {
                    Text(worstDay)
                        .fontDesign(.rounded)
                        .bold()
                        .foregroundStyle(habit.color)
                }
                .frame(height: 44)
            }
        }
        .cardContainer(fill: .background.secondary)
    }
}

private extension HabitDetailsView {

    var habitGridModel: HabitGridModel {
        var weeks = weekQuantitySamples.map { weekSamples in
            let todayIndex = weekSamples.samples.firstIndex(where: { Calendar.current.isDateInToday($0.date) })

            return HabitGridModel.Week(
                id: weekSamples.id,
                isComplete: weekSamples.samples.map { habit.quantityExceedsGoal($0.quantity) },
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

        return HabitGridModel(weeks: weeks)
    }
}

private extension HabitDetailsView {

    func loadGoalHistory() async {
        let eightWeeksSamples = await habit.measurement.fetchCollatedDailyQuantity(for: .trailingWeeksFromNow(8))
        let samples = await habit.measurement.fetchCollatedDailyQuantity(for: .trailingWeeksFromNow(30))

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
        for sample in eightWeeksSamples {
            guard let weekday = Calendar.current.weekday(for: sample.date) else { continue }

            if habit.quantityExceedsGoal(sample.quantity) {
                stats[weekday, default: 0] += 1
            }
        }

        let statsConstant = stats

        await MainActor.run {
            self.allSamplesEightWeeks = eightWeeksSamples
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
                measurement: .stepCount,
                value: 2000
            )
        )
    }
}
