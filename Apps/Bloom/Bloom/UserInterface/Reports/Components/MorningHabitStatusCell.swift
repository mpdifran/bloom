//
//  MorningHabitStatusCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-09.
//

import SFSafeSymbols
import SwiftUI
import HealthKit
import DataContainer

struct MorningHabitStatusCell: View {
  let habit: Habit

  var body: some View {
    HStack {
      Image(systemSymbol: SFSymbol(rawValue: habit.targetMetric.systemImage))
        .font(.title)
        .foregroundStyle(.tint)
        .frame(width: 35)

      Text(habit.targetMetric.name)
        .bold()
        .fontDesign(.rounded)

      Spacer()

      Text(habit.displayQuantity)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.tint)
    }
    .tint(habit.targetMetric.color)
  }
}

#Preview {
  List {
    MorningHabitStatusCell(
      habit: Habit(
        targetMetric: .timeInDaylight,
        timePeriod: .daily,
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
