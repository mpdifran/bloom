//
//  WorkoutExerciseSetCellEMOM.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-07.
//

import SwiftUI
import DataContainer
import AppUI

struct WorkoutExerciseSetCellEMOM: View {
  let exerciseSet: WorkoutExerciseSet
  let exercises: [WorkoutExercise]
  let currentTime: TimeInterval?
  let mode: WorkoutExerciseSetCell.Mode
  let isPeeking: Bool

  var body: some View {
    VStack {
      WorkoutExerciseSetCellHeaderView(mode: mode, exerciseSet: exerciseSet)

      WorkoutExerciseSetCellTitleView(
        symbol: exerciseSet.set.systemSymbol,
        title: exerciseSet.set.title,
        measurementDescription: exerciseSet.set.durationDescription,
        measurementSubtitle: "EMOM",
        mode: mode,
        isPeeking: isPeeking
      )

      if mode == .current || isPeeking {
        Divider()

        if let currentIndex {
          currentlyRunningContent(index: currentIndex)
        } else {
          summaryContent
        }
      }
    }
    .fontDesign(.rounded)
    .foregroundStyle(mode.color)
    .cardContainer(fill: mode == .current ? AnyShapeStyle(.tint) : AnyShapeStyle(.background))
    .tint(.green)
    .animation(.easeInOut, value: currentIndex)
  }
}

private extension WorkoutExerciseSetCellEMOM {

  var summaryContent: some View {
    VStack {
      ForEach(exercises) { exercise in
        ExerciseCell(exercise: exercise, showSummary: false)
      }
    }
  }

  func currentlyRunningContent(index: Int) -> some View {
    VStack {
      ExerciseCell(exercise: exercises[index], showSummary: true)

      Divider()

      if let nextIndex, let next = exercises.safeAccess(at: UInt(nextIndex)) {
        Text("Next: \(next.title)")
          .font(.body)
          .bold()
          .horizontalAlignment(.leading)
      }
    }
  }

  var currentIndex: Int? {
    guard let currentTime else { return nil }

    return Int(currentTime / 60) % exercises.count
  }

  var nextIndex: Int? {
    guard let currentIndex else { return nil }

    return (currentIndex + 1) % exercises.count
  }
}

private struct ExerciseCell: View {
  let exercise: WorkoutExercise
  let showSummary: Bool

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text("\(exercise.title)")
          .font(showSummary ? .title2 : .title3)
          .bold()

        if showSummary {
          Text(exercise.summary)
            .fixedSize(horizontal: false, vertical: true)
            .font(.body)
        }
      }

      Spacer()

      Text(exercise.measurementDescription)
        .font(showSummary ? .title2 : .title3)
        .bold()
    }
    .padding(.vertical, 1)
  }
}

#Preview {
  ScrollView {
    VStack {
      WorkoutExerciseSetCellEMOM(
        exerciseSet: .Preview.emom,
        exercises: WorkoutSet.Preview.emom.exercises ?? [],
        currentTime: nil,
        mode: .complete,
        isPeeking: false
      )
      WorkoutExerciseSetCellEMOM(
        exerciseSet: .Preview.emom,
        exercises: WorkoutSet.Preview.emom.exercises ?? [],
        currentTime: nil,
        mode: .current,
        isPeeking: false
      )
      WorkoutExerciseSetCellEMOM(
        exerciseSet: .Preview.emom,
        exercises: WorkoutSet.Preview.emom.exercises ?? [],
        currentTime: 116,
        mode: .current,
        isPeeking: false
      )
      WorkoutExerciseSetCellEMOM(
        exerciseSet: .Preview.emom,
        exercises: WorkoutSet.Preview.emom.exercises ?? [],
        currentTime: nil,
        mode: .upNext,
        isPeeking: false
      )
      WorkoutExerciseSetCellEMOM(
        exerciseSet: .Preview.emom,
        exercises: WorkoutSet.Preview.emom.exercises ?? [],
        currentTime: nil,
        mode: .upcoming,
        isPeeking: false
      )
      WorkoutExerciseSetCellEMOM(
        exerciseSet: .Preview.emom,
        exercises: WorkoutSet.Preview.emom.exercises ?? [],
        currentTime: nil,
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
