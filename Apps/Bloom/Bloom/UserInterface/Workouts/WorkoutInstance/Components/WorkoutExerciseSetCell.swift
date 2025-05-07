//
//  WorkoutExerciseSetCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-03.
//

import SwiftUI
import DataContainer
import AppUI
import SFSafeSymbols

extension WorkoutExerciseSetCell {
  enum Mode {
    case complete
    case current
    case upNext
    case upcoming

    init(index: Int, currentIndex: Int) {
      if index < currentIndex {
        self = .complete
      } else if index == currentIndex {
        self = .current
      } else if index == currentIndex + 1 {
        self = .upNext
      } else {
        self = .upcoming
      }
    }

    var color: Color {
      switch self {
      case .current:
        return .black
      case .complete:
        return .secondary
      default:
        return .text
      }
    }
  }
}

struct WorkoutExerciseSetCell: View {
  let exerciseSet: WorkoutExerciseSet
  let mode: Mode
  let isPeeking: Bool
  let currentSubTime: TimeInterval?

  var body: some View {
    Group {
      switch exerciseSet.kind {
      case .standard(let workoutExercise):
        WorkoutExerciseSetCellStandardExercise(
          exerciseSet: exerciseSet,
          exercise: workoutExercise,
          mode: mode,
          isPeeking: isPeeking
        )
      case .grouped(let exercises, let format):
        switch format {
        case .amrap:
          WorkoutExerciseSetCellAMRAP(
            exerciseSet: exerciseSet,
            exercises: exercises,
            mode: mode,
            isPeeking: isPeeking,
            subTime: currentSubTime
          )
        case .emom:
          WorkoutExerciseSetCellEMOM(
            exerciseSet: exerciseSet,
            exercises: exercises,
            currentTime: nil,
            mode: mode,
            isPeeking: isPeeking
          )
        default:
          EmptyView()
        }
      case .rest(let timeInterval):
        WorkoutExerciseSetCellRest(
          exerciseSet: exerciseSet,
          restTime: timeInterval,
          mode: mode,
          isPeeking: isPeeking,
          subTime: currentSubTime
        )
      @unknown default:
        EmptyView()
      }
    }
    .geometryGroup()
    .selectable()
    .animation(.easeInOut, value: mode)
    .animation(.easeInOut, value: isPeeking)
    .id(exerciseSet.id)
  }
}

#Preview {
  @Previewable @State var currentIndex = 1
  @Previewable @State var peekIndex: Int?

  let exerciseSets = WorkoutPlan.Preview.deadlifts.expandedExerciseSets()

  PreviewEnvironment {
    BloomScrollView {
      ForEachEnumerated(exerciseSets) { (index, exerciseSet) in
        WorkoutExerciseSetCell(
          exerciseSet: exerciseSet,
          mode: WorkoutExerciseSetCell.Mode(
            index: index,
            currentIndex: currentIndex
          ),
          isPeeking: index == peekIndex,
          currentSubTime: nil
        )
        .onTapGesture {
          let mode = WorkoutExerciseSetCell.Mode(
            index: index,
            currentIndex: currentIndex
          )
          guard mode == .upcoming || mode == .upNext else { return }

          if peekIndex == index {
            peekIndex = nil
          } else {
            peekIndex = index
          }
        }
      }
    }
    .tint(.green)
    .animation(.easeInOut, value: currentIndex)
    .animation(.easeInOut, value: peekIndex)
    .shelf {
      HStack {
        Button {
          let count = WorkoutPlan.Preview.deadlifts.expandedExerciseSets().count
          currentIndex = (currentIndex - 1) % count
          peekIndex = nil
        } label: {
          Text("Previous Exercise")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .tint(.yellow)

        Button {
          let count = WorkoutPlan.Preview.deadlifts.expandedExerciseSets().count
          currentIndex = (currentIndex + 1) % count
          peekIndex = nil
        } label: {
          Text("Next Exercise")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .tint(.green)
      }
    }
  }
}
