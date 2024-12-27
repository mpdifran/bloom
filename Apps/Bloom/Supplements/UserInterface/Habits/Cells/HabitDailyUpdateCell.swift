//
//  HabitDailyUpdateCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-19.
//

import SwiftUI
import DataContainer
import HealthKit

struct HabitDailyUpdateCell: View {
  let habit: Habit

  @ObservedObject private var viewModel: HabitDailyUpdateCellViewModel

  @State private var showConfetti = 0

  init(habit: Habit) {
    self.habit = habit
    self._viewModel = ObservedObject(wrappedValue: HabitDailyUpdateCellViewModel(habit: habit))
  }

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: habit.targetMetric.systemImage)
        .font(.title)
        .bold()
        .foregroundStyle(.tint)

      VStack(alignment: .leading, spacing: 8) {
        Text(habit.targetMetric.name)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)

        Group {
          if viewModel.goalCompletionState == .metGoal {
            HStack(spacing: 4) {
              Image(systemName: "checkmark")
              Text("Completed • \(viewModel.formattedDailyValue)")
            }
            .foregroundStyle(.tint)
          } else {
            HStack(spacing: 6) {
              ProgressBar(
                value: viewModel.dailyValue,
                target: habit.value,
                measurementStyle: .minimum
              )
              .frame(width: 50)

              Text(viewModel.formattedDailyValueNoUnits)
                .contentTransition(.numericText(value: viewModel.dailyValue))
                .foregroundStyle(.tint)

              Text("/ \(habit.displayQuantity)")
                .foregroundStyle(.secondary)
            }
            .animation(.default, value: viewModel.dailyValue)
          }
        }
        .font(.subheadline)
        .bold()
        .fontDesign(.rounded)
      }

      Spacer()

      DisclosureIndicator()
    }
    .tint(habit.targetMetric.color)
    .cardContainer()
    .standardConfetti(
      $showConfetti,
      colors: [
        habit.targetMetric.color,
        habit.targetMetric.color.darker(),
        habit.targetMetric.color.lighter()
      ]
    )
    .animation(.default, value: viewModel.dailyValue)
    .onShow {
      guard viewModel.shouldShowConfetti else { return }

      showConfetti += 1
      viewModel.shouldShowConfetti = false
    }
  }
}

#Preview {
  ScrollView {
    VStack {
      HabitDailyUpdateCell(
        habit: .init(
          targetMetric: .timeInDaylight,
          value: 30,
          unitString: HKUnit.minute().unitString,
          startDate: .now,
          isSuggested: true,
          isUserEdited: false,
          vitalKind: .sleepQuality
        )
      )
      HabitDailyUpdateCell(
        habit: .init(
          targetMetric: .calories,
          value: 1800,
          unitString: HKUnit.largeCalorie().unitString,
          startDate: .now,
          isSuggested: true,
          isUserEdited: false,
          vitalKind: .nutrition
        )
      )
    }
    .padding()
  }
  .groupedBackground()
}
