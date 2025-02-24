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
import Charts

struct HabitDetailsView: View {
  @State private var habit: Habit

  init(habit: Habit) {
    self._habit = State(initialValue: habit)
  }

  @State private var allSamplesTwelveWeeks = [DateQuantitySample]()
  @State private var weekQuantitySamples = [WeekQuantitySamples]() {
    didSet {
      Task { await loadHabitGridModel() }
    }
  }
  @State private var dailySamples = [DateQuantitySample]()
  @State private var averageValue: HKQuantity?
  @State private var dayStats = [Calendar.Weekday : Double]()
  @State private var habitGridModel = HabitGridModel()
  @State private var presentedSheet: AnyView?

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        titleSection

        HabitGrid(model: habitGridModel)
          .padding(.bottom)

        statsSection
          .padding(.horizontal)
          .padding(.bottom)

        historyChart
          .padding(.horizontal)
      }
      .toolbar {
        ToolbarItem(placement: .principal) {
          Image(systemName: habit.targetMetric.systemImage)
            .symbolVariant(.fill)
            .bold()
        }
        ToolbarItem(placement: .primaryAction) {
          Menu("Options", systemImage: "ellipsis.circle") {
            Button("Edit Goal", systemImage: "slider.horizontal.3") {
              presentedSheet = EditUserAddedHabitView(habit: habit) { habit in
                guard let habit else {
                  dismiss()
                  return
                }
                self.habit = habit
              }.asAny
            }
          }
        }
      }
    }
    .tint(habit.targetMetric.color)
    .navigationTitle("Habit Details")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await loadGoalHistory()
    }
    .sheet($presentedSheet)
  }
}

private extension HabitDetailsView {

  var titleSection: some View {
    HStack {
      Text(habit.targetMetric.name)
        .font(.title)
        .bold()
        .fontDesign(.rounded)

      Spacer()

      VStack(alignment: .trailing) {
        Text("Goal")
          .foregroundStyle(.secondary)
          .font(.caption)
        Text(habit.displayQuantity)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)
      }
    }
    .padding()
  }

  @ViewBuilder
  var statsSection: some View {
    if dayStats.isNotEmpty {
      VStack {
        HStack {
          Spacer()

          if let worstDay = dayStats.min(by: { $0.value < $1.value })?.key.name {
            VStack {
              Text(worstDay)
                .font(.title)
                .bold()
                .fontDesign(.rounded)
                .minimumScaleFactor(0.3)

              Text("Worst Day")
                .font(.caption)
                .foregroundStyle(.secondary)
                .bold()
            }
            .frame(maxWidth: .infinity)
          }

          Spacer()

          Divider()

          Spacer()

          if let bestDay = dayStats.max(by: { $0.value < $1.value })?.key.name {
            VStack {
              Text(bestDay)
                .font(.title)
                .bold()
                .fontDesign(.rounded)
                .minimumScaleFactor(0.3)

              Text("Best Day")
                .font(.caption)
                .foregroundStyle(.secondary)
                .bold()
            }
            .frame(maxWidth: .infinity)
          }

          Spacer()
        }
        .cardContainer(fill: .background.secondary)
      }
    }
  }

  var historyChart: some View {
    VStack(alignment: .leading) {
      VitalDetailChartTitleView(
        title: "Daily Values",
        value: averageValue?.displayString(for: habit.unit) ?? ""
      )

      Chart{
        ForEach(dailySamples) { sample in
          BarMark(
            x: .value("Date", sample.date),
            y: .value(habit.targetMetric.name, sample.quantity.localizedValue(for: habit.unit))
          )
          .foregroundStyle(habit.quantityMeetsGoal(sample.quantity) ? AnyShapeStyle(.tint) : AnyShapeStyle(.tint.opacity(0.3)))
        }

        switch habit.targetMetric.measurementStyle {
        case .minimum:
          RuleMark(
            y: .value("Goal", HKQuantity(unit: habit.unit, doubleValue: habit.value).localizedValue(for: habit.unit))
          )
          .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
          .foregroundStyle(.tint)

          RectangleMark(
            yStart: .value("Min Goal", HKQuantity(unit: habit.unit, doubleValue: habit.value).localizedValue(for: habit.unit)),
            yEnd: .value("Max Goal", HKQuantity(unit: habit.unit, doubleValue: habit.value * 2).localizedValue(for: habit.unit))
          )
          .foregroundStyle(
            LinearGradient(
              colors: [habit.targetMetric.color.opacity(0.3), .clear],
              startPoint: .bottom,
              endPoint: .top
            )
          )
        case .range:
          RectangleMark(
            yStart: .value("Min Goal", habit.rangeMinGoal.localizedValue(for: habit.unit)),
            yEnd: .value("Max Goal", habit.rangeMaxGoal.localizedValue(for: habit.unit))
          )
          .foregroundStyle(.tint.opacity(0.3))

          RuleMark(
            y: .value("Min Goal", habit.rangeMinGoal.localizedValue(for: habit.unit))
          )
          .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
          .foregroundStyle(.tint)

          RuleMark(
            y: .value("Max Goal", habit.rangeMaxGoal.localizedValue(for: habit.unit))
          )
          .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
          .foregroundStyle(.tint)
        @unknown default:
          fatalError("Unknown goal type")
        }
      }
      .frame(height: 200)
    }
  }
}

private extension HabitDetailsView {

  func loadHabitGridModel() async {
    let targetMetric = habit.targetMetric

    Task.detached {
      let context = ContainerHolder.shared.createContext()

      let habitHistory: [Habit]
      do {
        habitHistory = try context.fetchHabits(for: targetMetric)
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
          return referenceHabit.quantityMeetsGoal(sample.quantity)
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
      dateRange: .trailingWeeksFromEndOfToday(12)
    )
    let samples = await habit.targetMetric.fetchCollatedDailyQuantity(
      unit: habit.unit,
      dateRange: .trailingWeeksFromEndOfToday(30)
    )

    let currentWeekOfYear = Calendar.current.weekOfYear(for: .now) ?? 52
    let groupedByWeekSamples = samples.grouped { sample in
      guard let weekOfYear = Calendar.current.weekOfYear(for: sample.date) else { return -1 }

      // The week IDs always need to be 0 on the right and a positive incrementing number to the left for the animation to work correctly.
      if currentWeekOfYear < weekOfYear {
        return currentWeekOfYear - weekOfYear + 52
      }
      return currentWeekOfYear - weekOfYear
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

    var statsIntermediate = [Calendar.Weekday : [Double]]()
    for sample in twelveWeeksSamples {
      guard let weekday = Calendar.current.weekday(for: sample.date) else { continue }

      statsIntermediate[weekday, default: []].append(sample.quantity.doubleValue(for: habit.unit))
    }
    var stats = [Calendar.Weekday : Double]()
    for weekday in statsIntermediate.keys {
      stats[weekday] = statsIntermediate[weekday]?.average(keyPath: \.self) ?? 0
    }
    let statsConstant = stats

    let averageValue = twelveWeeksSamples.map({ $0.quantity.doubleValue(for: habit.unit) }).average(keyPath: \.self)
    let averageQuantity = HKQuantity(unit: habit.unit, doubleValue: averageValue)

    await MainActor.run {
      self.allSamplesTwelveWeeks = twelveWeeksSamples
      self.weekQuantitySamples = weekSamples
      self.dayStats = statsConstant
      self.dailySamples = samples.suffix(30)
      self.averageValue = averageQuantity
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
      habit: Habit(
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
