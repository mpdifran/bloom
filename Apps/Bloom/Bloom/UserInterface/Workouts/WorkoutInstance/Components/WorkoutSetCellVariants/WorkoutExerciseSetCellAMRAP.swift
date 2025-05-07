//
//  WorkoutExerciseSetCellAMRAP.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-07.
//

import SwiftUI
import DataContainer
import AppUI

struct WorkoutExerciseSetCellAMRAP: View {
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
        measurementSubtitle: "AMRAP",
        mode: mode,
        isPeeking: isPeeking
      )

      if mode == .current || isPeeking {
        Divider()

        VStack(alignment: .leading) {
          ForEach(exercises) { exercise in
            HStack {
              VStack(alignment: .leading) {
                Text("\(exercise.title)")
                  .font(.title3)
                  .bold()
                Text(exercise.summary)
                  .fixedSize(horizontal: false, vertical: true)
                  .font(.body)
              }

              Spacer()

              Text(exercise.measurementDescription)
                .font(.title3)
                .bold()
            }
            .padding(.vertical, 1)
          }
        }
        .horizontalAlignment(.leading)
      }
    }
    .fontDesign(.rounded)
    .foregroundStyle(mode.color)
    .cardContainer(fill: mode == .current ? AnyShapeStyle(.tint) : AnyShapeStyle(.background))
    .tint(.green)
    .animation(.default, value: subTime)
  }
}

private extension WorkoutExerciseSetCellAMRAP {

  var timeDescription: String {
    let duration = exerciseSet.set.duration ?? 0
    let time: TimeInterval
    if let subTime {
      time = min(duration - subTime + 1, duration)
    } else {
      time = duration ?? 0
    }
    return DateFormatter.timeIntervalHourMinuteSecondAbbreviated.string(from: DateComponents(second: Int(time))) ?? ""
  }
}

#Preview {
  ScrollView {
    VStack {
      WorkoutExerciseSetCellAMRAP(
        exerciseSet: .Preview.amrap,
        exercises: WorkoutSet.Preview.amrap.exercises ?? [],
        mode: .complete,
        isPeeking: false,
        subTime: nil
      )
      WorkoutExerciseSetCellAMRAP(
        exerciseSet: .Preview.amrap,
        exercises: WorkoutSet.Preview.amrap.exercises ?? [],
        mode: .current,
        isPeeking: false,
        subTime: 111
      )
      WorkoutExerciseSetCellAMRAP(
        exerciseSet: .Preview.amrap,
        exercises: WorkoutSet.Preview.amrap.exercises ?? [],
        mode: .upNext,
        isPeeking: false,
        subTime: nil
      )
      WorkoutExerciseSetCellAMRAP(
        exerciseSet: .Preview.amrap,
        exercises: WorkoutSet.Preview.amrap.exercises ?? [],
        mode: .upcoming,
        isPeeking: false,
        subTime: nil
      )
      WorkoutExerciseSetCellAMRAP(
        exerciseSet: .Preview.amrap,
        exercises: WorkoutSet.Preview.amrap.exercises ?? [],
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
