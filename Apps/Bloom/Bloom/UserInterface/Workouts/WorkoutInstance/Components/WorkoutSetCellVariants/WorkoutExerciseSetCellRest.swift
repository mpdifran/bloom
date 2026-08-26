//
//  WorkoutExerciseSetCellRest.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-07.
//

import SwiftUI
import DataContainer

struct WorkoutExerciseSetCellRest: View {
  let exerciseSet: WorkoutExerciseSet
  let restTime: TimeInterval
  let mode: WorkoutExerciseSetCell.Mode
  let isPeeking: Bool
  let subTime: TimeInterval?

  var body: some View {
    VStack(alignment: .leading) {
      WorkoutExerciseSetCellHeaderView(mode: mode, exerciseSet: exerciseSet)

      WorkoutExerciseSetCellTitleView(
        symbol: .figureStand,
        title: String(localized: "Rest", comment: "Workout set type"),
        measurementDescription: timeDescription,
        mode: mode,
        isPeeking: isPeeking
      )
    }
    .fontDesign(.rounded)
    .foregroundStyle(mode.color)
    .cardContainer(fill: mode == .current ? AnyShapeStyle(.tint) : AnyShapeStyle(.background))
    .tint(.blue)
    .animation(.default, value: subTime)
  }
}

private extension WorkoutExerciseSetCellRest {

  var timeDescription: String {
    let time: TimeInterval
    if let subTime {
      time = restTime - subTime + 1
    } else {
      time = restTime
    }
    return DateFormatter.timeIntervalHourMinuteSecondAbbreviated.string(from: DateComponents(second: Int(time))) ?? ""
  }
}

#Preview {
  ScrollView {
    VStack {
      WorkoutExerciseSetCellRest(
        exerciseSet: .Preview.deadlifts,
        restTime: 60,
        mode: .complete,
        isPeeking: false,
        subTime: nil
      )
      WorkoutExerciseSetCellRest(
        exerciseSet: .Preview.deadlifts,
        restTime: 60,
        mode: .current,
        isPeeking: false,
        subTime: 16
      )
      WorkoutExerciseSetCellRest(
        exerciseSet: .Preview.deadlifts,
        restTime: 60,
        mode: .upNext,
        isPeeking: false,
        subTime: nil
      )
      WorkoutExerciseSetCellRest(
        exerciseSet: .Preview.deadlifts,
        restTime: 60,
        mode: .upcoming,
        isPeeking: true,
        subTime: nil
      )
      WorkoutExerciseSetCellRest(
        exerciseSet: .Preview.deadlifts,
        restTime: 60,
        mode: .upcoming,
        isPeeking: false,
        subTime: nil
      )
    }
    .padding()
  }
  .background {
    Rectangle()
      .fill(.background.secondary)
      .ignoresSafeArea()
  }
}
