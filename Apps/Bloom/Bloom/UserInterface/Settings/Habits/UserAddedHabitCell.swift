//
//  UserAddedHabitCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-21.
//

import SFSafeSymbols
import SwiftUI
import DataContainer
import HealthKit

struct UserAddedHabitCell: View {
  let habit: Habit

  var body: some View {
    HStack {
      Image(systemSymbol: SFSymbol(rawValue: habit.targetMetric.systemImage))
        .font(.title)
        .foregroundStyle(habit.targetMetric.color)
        .frame(width: 40)

      VStack(alignment: .leading) {
        Text(habit.targetMetric.name)
          .bold()
        Text(habit.timePeriod.name)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Text(habit.displayQuantity)
        .font(.body)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(habit.targetMetric.color)
    }
  }
}

#Preview {
  PreviewEnvironment {
    UserAddedHabitCell(
      habit: Habit(
        targetMetric: .walkingRunningDistance,
        timePeriod: .daily,
        value: 5,
        unitString: HKUnit.meterUnit(with: .kilo).unitString,
        startDate: .now,
        isSuggested: false,
        isUserEdited: true
      )
    )
  }
}
