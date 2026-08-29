//
//  WorkoutExerciseSetCellTabata.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-07.
//

import SwiftUI
import DataContainer
import AppUI

struct WorkoutExerciseSetCellTabata: View {
  let exerciseSet: WorkoutExerciseSet
  let exercises: [WorkoutExercise]
  let mode: WorkoutExerciseSetCell.Mode
  let isPeeking: Bool
  let subTime: TimeInterval?

  var body: some View {
    VStack {
      WorkoutExerciseSetCellHeaderView(mode: mode, exerciseSet: exerciseSet)

      WorkoutExerciseSetCellTitleView(
        symbol: exerciseSet.set.systemSymbol,
        title: exerciseSet.set.title,
        measurementDescription: timeDescription,
        measurementSubtitle: String(localized: "TABATA", comment: "Workout format: Tabata intervals"),
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
    .animation(.default, value: currentIndex)
    .animation(.default, value: subTime)
  }
}

private extension WorkoutExerciseSetCellTabata {

  var timeDescription: String {
    let duration = exerciseSet.set.duration ?? 0
    let time: TimeInterval
    if let subTime {
      time = min(duration - subTime + 1, duration)
    } else {
      time = duration
    }
    return DateFormatter.timeIntervalHourMinuteSecondAbbreviated.string(from: DateComponents(second: Int(time))) ?? ""
  }

  var summaryContent: some View {
    VStack {
      ForEach(exercises) { exercise in
        ExerciseCell(exercise: exercise, remainingDuration: 20)
      }
    }
  }

  func currentlyRunningContent(index: Int) -> some View {
    VStack {

      if isResting {
        RestCell(remainingDuration: remainingRestTime)
      } else {
        ExerciseCell(
          exercise: exercises[index],
          remainingDuration: remainingWorkTime
        )
      }
    }
  }

  var isResting: Bool {
    guard let subTime else { return false }

    let cycleDuration = 30.0 // 20s work + 10s rest
    let workDuration = 20.0

    let elapsedInCycle = subTime.truncatingRemainder(dividingBy: cycleDuration)

    return elapsedInCycle >= workDuration
  }

  var remainingWorkTime: TimeInterval {
    guard let subTime else { return 0 }

    let cycleDuration = 30.0 // 20s work + 10s rest
    let workDuration = 20.0

    let elapsedInCycle = subTime.truncatingRemainder(dividingBy: cycleDuration)

    if elapsedInCycle < workDuration {
      return workDuration - elapsedInCycle
    }
    return 0
  }

  var remainingRestTime: TimeInterval {
    guard let subTime else { return 0 }

    let cycleDuration = 30.0 // 20s work + 10s rest
    let workDuration = 20.0

    let elapsedInCycle = subTime.truncatingRemainder(dividingBy: cycleDuration)

    if elapsedInCycle >= workDuration {
      return cycleDuration - elapsedInCycle
    }
    return 0
  }

  var currentIndex: Int? {
    guard let subTime else { return nil }

    return Int(subTime / 60) % exercises.count
  }

  var nextIndex: Int? {
    guard let currentIndex else { return nil }

    return (currentIndex + 1) % exercises.count
  }
}

private struct ExerciseCell: View {
  let exercise: WorkoutExercise
  let remainingDuration: TimeInterval

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(verbatim: "\(exercise.title)")
          .font(.title2)
          .bold()

        Text(exercise.summary)
          .fixedSize(horizontal: false, vertical: true)
          .font(.body)
      }

      Spacer()

      Text(DateFormatter.timeIntervalHourMinuteSecondAbbreviated.string(from: DateComponents(second: Int(remainingDuration))) ?? "")
        .font(.title2)
        .bold()
    }
    .padding(.vertical, 1)
  }
}

private struct RestCell: View {
  let remainingDuration: TimeInterval

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text("Rest")
          .font(.title2)
          .bold()
      }

      Spacer()

      Text(DateFormatter.timeIntervalHourMinuteSecondAbbreviated.string(from: DateComponents(second: Int(remainingDuration))) ?? "")
        .font(.title2)
        .bold()
    }
    .padding(.vertical, 1)
  }
}

#Preview {
  ScrollView {
    VStack {
      WorkoutExerciseSetCellTabata(
        exerciseSet: .Preview.tabata,
        exercises: WorkoutSet.Preview.tabata.exercises ?? [],
        mode: .complete,
        isPeeking: false,
        subTime: nil
      )
      WorkoutExerciseSetCellTabata(
        exerciseSet: .Preview.tabata,
        exercises: WorkoutSet.Preview.tabata.exercises ?? [],
        mode: .current,
        isPeeking: false,
        subTime: nil
      )
      WorkoutExerciseSetCellTabata(
        exerciseSet: .Preview.tabata,
        exercises: WorkoutSet.Preview.tabata.exercises ?? [],
        mode: .current,
        isPeeking: false,
        subTime: 15
      )
      WorkoutExerciseSetCellTabata(
        exerciseSet: .Preview.tabata,
        exercises: WorkoutSet.Preview.tabata.exercises ?? [],
        mode: .current,
        isPeeking: false,
        subTime: 25
      )
      WorkoutExerciseSetCellTabata(
        exerciseSet: .Preview.tabata,
        exercises: WorkoutSet.Preview.tabata.exercises ?? [],
        mode: .upNext,
        isPeeking: false,
        subTime: nil
      )
      WorkoutExerciseSetCellTabata(
        exerciseSet: .Preview.tabata,
        exercises: WorkoutSet.Preview.tabata.exercises ?? [],
        mode: .upcoming,
        isPeeking: false,
        subTime: nil
      )
      WorkoutExerciseSetCellTabata(
        exerciseSet: .Preview.tabata,
        exercises: WorkoutSet.Preview.tabata.exercises ?? [],
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
