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

  var body: some View {
    VStack(alignment: .leading) {
      WorkoutExerciseSetCellHeaderView(mode: mode, exerciseSet: exerciseSet)

      WorkoutExerciseSetCellTitleView(
        symbol: exerciseSet.set.systemSymbol,
        title: exercise.title,
        measurementDescription: exercise.measurementDescription,
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
  }
}

#Preview {
  ScrollView {
    VStack {
      WorkoutExerciseSetCellStandardExercise(
        exerciseSet: .Preview.deadlifts,
        exercise: .Preview.deadlifts,
        mode: .complete,
        isPeeking: false
      )
      WorkoutExerciseSetCellStandardExercise(
        exerciseSet: .Preview.deadlifts,
        exercise: .Preview.deadlifts,
        mode: .current,
        isPeeking: false
      )
      WorkoutExerciseSetCellStandardExercise(
        exerciseSet: .Preview.deadlifts,
        exercise: .Preview.deadlifts,
        mode: .upNext,
        isPeeking: false
      )
      WorkoutExerciseSetCellStandardExercise(
        exerciseSet: .Preview.deadlifts,
        exercise: .Preview.deadlifts,
        mode: .upcoming,
        isPeeking: true
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
