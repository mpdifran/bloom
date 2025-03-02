//
//  EveningHabitStatusCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-09.
//

import SFSafeSymbols
import SwiftUI
import HealthKit
import DataContainer

struct EveningHabitStatusCell: View {
  let habit: Habit

  @ObservedObject private var viewModel: HabitDailyUpdateCellViewModel

  init(habit: Habit) {
    self.habit = habit
    self._viewModel = ObservedObject(wrappedValue: HabitDailyUpdateCellViewModel(habit: habit))
  }

  var body: some View {
    HStack {
      CompletionCheckmarkView(
        state: viewModel.goalCompletionState,
        colorize: true
      )

      VStack(alignment: .leading) {
        Text(habit.targetMetric.name)
          .bold()
        Text(viewModel.goalDifferenceSummary)
          .foregroundStyle(.secondary)
          .font(.caption)
      }

      Spacer()

      Image(systemSymbol: SFSymbol(rawValue: habit.targetMetric.systemImage))
        .font(.title2)
        .foregroundStyle(.tint)

      DisclosureIndicator()
    }
    .padding(.vertical, 2)
    .tint(habit.targetMetric.color)
  }
}

#Preview {
  List {
    EveningHabitStatusCell(
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
    EveningHabitStatusCell(
      habit: Habit(
        targetMetric: .stepCount,
        value: 5000,
        unitString: HKUnit.count().unitString,
        startDate: .now,
        isSuggested: true,
        isUserEdited: false,
        vitalKind: .sleepQuality
      )
    )
    EveningHabitStatusCell(
      habit: Habit(
        targetMetric: .targetHeartRateZone2,
        value: 30,
        unitString: HKUnit.minute().unitString,
        startDate: .now,
        isSuggested: true,
        isUserEdited: false,
        vitalKind: .sleepQuality
      )
    )
  }
  .listStyle(.plain)
}
