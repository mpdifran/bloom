//
//  HabitDailyUpdateCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-19.
//

import SFSafeSymbols
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

  init(habitViewModel: HabitDailyUpdateCellViewModel) {
    self.habit = habitViewModel.habit
    self._viewModel = ObservedObject(wrappedValue: habitViewModel)
  }

  var body: some View {
    HStack(spacing: 14) {
      Image(systemSymbol: SFSymbol(rawValue: habit.targetMetric.systemImage)) // TODO: Zach - see if we need to map symbols from DataContainer
        .font(.title)
        .foregroundStyle(.tint)
        .frame(width: 40)

      VStack(alignment: .leading, spacing: 8) {
        Text(habit.targetMetric.name)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)

        Group {
          if viewModel.goalCompletionState == .metGoal {
            HStack(spacing: 4) {
              Image(systemSymbol: .checkmark)
              Text("Completed • \(viewModel.formattedDailyValue)")
            }
            .foregroundStyle(.tint)
          } else if viewModel.goalCompletionState == .exceededGoal {
            HStack(spacing: 4) {
              Image(systemSymbol: .chevronUpCircleFill)
                .foregroundStyle(.white, .mutedRed)
              Text("Exceeded goal by \(viewModel.formattedExceededDailyValue)")
            }
            .foregroundStyle(.mutedRed)
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
        habit: Habit(
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
        habit: Habit(
          targetMetric: .calories,
          value: 1800,
          unitString: HKUnit.largeCalorie().unitString,
          startDate: .now,
          isSuggested: true,
          isUserEdited: false,
          vitalKind: .nutrition
        )
      )
      HabitDailyUpdateCell(
        habit: Habit(
          targetMetric: .bikeDistance,
          value: -20,
          unitString: HKUnit.meterUnit(with: .kilo).unitString,
          startDate: .now,
          isSuggested: true,
          isUserEdited: false,
          vitalKind: .activityLevel
        )
      )
    }
    .padding()
  }
  .groupedBackground()
}
