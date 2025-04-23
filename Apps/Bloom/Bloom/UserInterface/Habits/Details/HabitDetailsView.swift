//
//  HabitDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-20.
//

import SFSafeSymbols
import SwiftUI
import DataContainer
import HealthKit
import SwiftData
import Charts

struct HabitDetailsView: View {
  @State private var viewModel: ViewModel

  init(habit: Habit) {
    self._viewModel = State(initialValue: ViewModel(habit: habit))
  }

  @State private var presentedSheet: AnyView?

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    BloomScrollView(spacing: 20) {
      titleSection

      HabitGrid(model: viewModel.habitGridModel)
        .padding(.bottom)

      Group {
        statsSection
          .padding(.bottom)
        historyChart
        notesSection
      }
      .padding(.horizontal)
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        Image(systemSymbol: SFSymbol(rawValue: viewModel.habit.targetMetric.systemImage))
          .symbolVariant(.fill)
          .bold()
      }
      ToolbarItem(placement: .primaryAction) {
        Menu("Options", systemImage: "ellipsis.circle") {
          Button("Edit Goal", systemImage: "slider.horizontal.3") {
            presentedSheet = EditUserAddedHabitView(habit: viewModel.habit) { habit in
              guard let habit else {
                dismiss()
                return
              }
              self.viewModel.habit = habit
            }.asAny
          }
        }
      }
    }
    .tint(viewModel.habit.targetMetric.color)
    .navigationTitle("Habit Details")
    .navigationBarTitleDisplayMode(.inline)
    .animation(.bouncy(duration: 1), value: viewModel.todayValue)
    .task {
      await Delay(500)
      await viewModel.loadTodayValue()
    }
    .task {
      await viewModel.loadGoalHistory()
    }
    .sheet($presentedSheet)
  }
}

private extension HabitDetailsView {

  var titleSection: some View {
    VStack {
      Text(viewModel.todayValue.displayString(for: viewModel.habit.unit))
        .font(.system(size: 60))
        .foregroundStyle(viewModel.habit.targetMetric.color)
        .lineLimit(1)
        .minimumScaleFactor(0.25)
        .contentTransition(.numericText(value: viewModel.todayValue.doubleValue(for: viewModel.habit.unit)))

      HStack {
        Text(viewModel.habit.targetMetric.name)
        Text("•")
        Text("Today")
      }
      .foregroundStyle(.secondary)
      .font(.body)
    }
    .bold()
    .fontDesign(.rounded)
    .padding()
    .padding(.vertical)
  }

  @ViewBuilder
  var statsSection: some View {
    if viewModel.dayStats.isNotEmpty {
      VStack {

        HStack {
          Text("\(viewModel.habit.timePeriod.name) Goal")

          Spacer()

          Text(viewModel.habit.displayQuantity)
            .font(.title2)
        }
        .bold()
        .fontDesign(.rounded)

        Divider()

        HStack {
          Spacer()

          if let worstDay = viewModel.dayStats.min(by: { $0.value < $1.value })?.key.name {
            VStack {
              Text(worstDay)
                .font(.title2)
                .bold()
                .fontDesign(.rounded)
                .lineLimit(1)
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

          if let bestDay = viewModel.dayStats.max(by: { $0.value < $1.value })?.key.name {
            VStack {
              Text(bestDay)
                .font(.title2)
                .bold()
                .fontDesign(.rounded)
                .lineLimit(1)
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
      }
      .cardContainer(fill: .background.secondary)
    }
  }

  var historyChart: some View {
    VStack(alignment: .leading) {
      VitalDetailChartTitleView(
        title: "Daily Values",
        value: viewModel.averageValue?.displayString(for: viewModel.habit.unit) ?? ""
      )

      Chart{
        ForEach(viewModel.dailySamples) { sample in
          BarMark(
            x: .value("Date", sample.date),
            y: .value(viewModel.habit.targetMetric.name, sample.quantity.localizedValue(for: viewModel.habit.unit))
          )
          .foregroundStyle(viewModel.sampleMeetsGoal(sample) ? AnyShapeStyle(.tint) : AnyShapeStyle(.tint.opacity(0.3)))
        }

        ForEach(viewModel.goalRanges) { range in
          switch viewModel.habit.targetMetric.measurementStyle {
          case .minimum:
            RectangleMark(
              xStart: .value("Start", range.startDate),
              xEnd: .value("End", range.endDate),
              yStart: .value("Min Goal", range.minGoal),
              yEnd: .value("Max Goal", range.maxGoal)
            )
            .foregroundStyle(
              LinearGradient(
                colors: [viewModel.habit.targetMetric.color.opacity(0.3), .clear],
                startPoint: .bottom,
                endPoint: .top
              )
            )
            RuleMark(
              xStart: .value("Start", range.startDate),
              xEnd: .value("End", range.endDate),
              y: .value("Goal", range.minGoal)
            )
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
            .foregroundStyle(.tint)
          case .range:
            RectangleMark(
              xStart: .value("Start", range.startDate),
              xEnd: .value("End", range.endDate),
              yStart: .value("Min Goal", range.minGoal),
              yEnd: .value("Max Goal", range.maxGoal)
            )
            .foregroundStyle(.tint.opacity(0.3))

            RuleMark(
              xStart: .value("Start", range.startDate),
              xEnd: .value("End", range.endDate),
              y: .value("Min Goal", viewModel.habit.rangeMinGoal.localizedValue(for: viewModel.habit.unit))
            )
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
            .foregroundStyle(.tint)

            RuleMark(
              xStart: .value("Start", range.startDate),
              xEnd: .value("End", range.endDate),
              y: .value("Max Goal", viewModel.habit.rangeMaxGoal.localizedValue(for: viewModel.habit.unit))
            )
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
            .foregroundStyle(.tint)
          @unknown default:
            fatalError("Unknown goal type")
          }
        }
      }
      .frame(height: 200)
    }
  }

  @ViewBuilder
  var notesSection: some View {
    if let habitSummaryText {
      VStack {
        SectionTitleView("Notes")
          .padding(.horizontal)
        Text(habitSummaryText)
          .horizontalAlignment(.leading)
          .multilineTextAlignment(.leading)
          .cardContainer(fill: .background.secondary)
      }
    }
  }
}

private extension HabitDetailsView {

  var habitSummaryText: String? {
    var workoutTypes = [HKWorkoutActivityType]()
    switch viewModel.habit.targetMetric {
    case .mobilityAndFlexibilityDuration:
      workoutTypes = .mobilityAndFlexibilityTypes
    case .strengthTrainingDuration:
      workoutTypes = .strengthTrainingTypes
    case .cardioDuration:
      workoutTypes = .cardioTypes
    case .highIntensityIntervalTrainingDuration:
      workoutTypes = .highIntensityIntervalTrainingTypes
    default:
      return nil
    }

    let listFormatter = ListFormatter()
    let workoutNames = workoutTypes.map(\.name)

    guard let workouts = listFormatter.string(from: workoutNames) else {
      return nil
    }

    return "This goal tracks time spent performing \(workouts) workouts."
  }
}

struct WeekQuantitySamples: Identifiable {
  let id: Int
  let referenceDate: Date
  let samples: [DateQuantitySample]
}

#Preview("Water Intake") {
  NavigationStack {
    HabitDetailsView(
      habit: Habit(
        targetMetric: .waterIntake,
        timePeriod: .daily,
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

#Preview("Strength Training") {
  NavigationStack {
    HabitDetailsView(
      habit: Habit(
        targetMetric: .strengthTrainingDuration,
        timePeriod: .weekly,
        value: 30,
        unitString: HKUnit.minute().unitString,
        startDate: .now,
        isSuggested: true,
        isUserEdited: false,
        vitalKind: .exerciseEffectiveness
      )
    )
  }
}
