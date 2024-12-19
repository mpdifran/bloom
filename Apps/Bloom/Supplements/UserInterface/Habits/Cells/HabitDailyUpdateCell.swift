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
    VStack(spacing: 26) {
      HStack {
        Image(systemName: habit.targetMetric.systemImage)
          .font(.title2)
          .bold()

        Text(habit.targetMetric.name)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)

        Spacer()

        DisclosureIndicator()
          .bold()
      }

      VStack {
        HStack {
          if viewModel.goalCompletionState == .metGoal {
            HStack {
              Image(systemName: "checkmark")
              Text("Completed")
            }
            .foregroundStyle(.tint)
          } else {
            Text(viewModel.formattedDailyValue)
              .foregroundStyle(.tint)
              .contentTransition(.numericText(value: viewModel.dailyValue))
              .animation(.default, value: viewModel.dailyValue)
          }

          Spacer()

          if viewModel.goalCompletionState == .metGoal {
            Text("\(viewModel.formattedDailyValueNoUnits) / \(habit.displayQuantity)")
              .contentTransition(.numericText(value: viewModel.dailyValue))
              .animation(.default, value: viewModel.dailyValue)
              .foregroundStyle(.tint)
          } else {
            Text("\(habit.displayQuantity)")
              .foregroundStyle(.secondary)
          }
        }
        .font(.body)
        .bold()
        .fontDesign(.rounded)

        ProgressBar(
          value: viewModel.dailyValue,
          target: habit.value,
          measurementStyle: .minimum
        )
      }
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
