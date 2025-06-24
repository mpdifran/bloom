//
//  WorkoutExerciseSetCellStandardExercise.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-07.
//

import SwiftUI
import DataContainer

struct WorkoutExerciseSetCellStandardExercise: View {
  let exerciseSet: WorkoutExerciseSet
  let exercise: WorkoutExercise
  let mode: WorkoutExerciseSetCell.Mode
  let isPeeking: Bool
  let subTime: TimeInterval?

  var body: some View {
    VStack(alignment: .leading) {
      WorkoutExerciseSetCellHeaderView(mode: mode, exerciseSet: exerciseSet)

      WorkoutExerciseSetCellTitleView(
        symbol: exerciseSet.set.systemSymbol,
        title: exercise.title,
        measurementDescription: measurementDescription,
        measurementNumericValue: remainingTime,
        mode: mode,
        isPeeking: isPeeking
      )

      if mode == .current || isPeeking {
        Text(exercise.summary)
          .fixedSize(horizontal: false, vertical: true)
          .font(.body)
      }
    }
    .fontDesign(.rounded)
    .foregroundStyle(mode.color)
    .cardContainer(fill: mode == .current ? AnyShapeStyle(.tint) : AnyShapeStyle(.background))
    .tint(.green)
    .animation(.default, value: subTime)
  }
}

private extension WorkoutExerciseSetCellStandardExercise {

  var remainingTime: TimeInterval {
    if exercise.duration > 0, let subTime, mode == .current {
      return min(max(0, exercise.duration - subTime + 1), exercise.duration)
    }
    return exercise.duration
  }

  var measurementDescription: String {
    // If exercise has duration and we're showing countdown
    if exercise.duration > 0, let subTime, mode == .current {
      return DateFormatter.timeIntervalHourMinuteSecondAbbreviated.string(from: DateComponents(second: Int(remainingTime))) ?? ""
    } else {
      // Use default measurement description
      return exercise.measurementDescription
    }
  }
}

#Preview {
  ScrollView {
    VStack {
      WorkoutExerciseSetCellStandardExercise(
        exerciseSet: .Preview.deadlifts,
        exercise: .Preview.deadlifts,
        mode: .complete,
        isPeeking: false,
        subTime: nil
      )
      WorkoutExerciseSetCellStandardExercise(
        exerciseSet: .Preview.deadlifts,
        exercise: .Preview.deadlifts,
        mode: .current,
        isPeeking: false,
        subTime: 45
      )
      WorkoutExerciseSetCellStandardExercise(
        exerciseSet: .Preview.deadlifts,
        exercise: .Preview.deadlifts,
        mode: .upNext,
        isPeeking: false,
        subTime: nil
      )
      WorkoutExerciseSetCellStandardExercise(
        exerciseSet: .Preview.deadlifts,
        exercise: .Preview.deadlifts,
        mode: .upcoming,
        isPeeking: true,
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
