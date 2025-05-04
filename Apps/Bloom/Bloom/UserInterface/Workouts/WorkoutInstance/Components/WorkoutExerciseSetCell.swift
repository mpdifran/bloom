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
  }
}

struct WorkoutExerciseSetCell: View {
  let exerciseSet: WorkoutExerciseSet
  let mode: Mode
  let isPeeking: Bool

  var body: some View {
    Group {
      switch exerciseSet.kind {
      case .exercise(let workoutExercise):
        exerciseContent(exercise: workoutExercise)
      case .rest(let timeInterval):
        restContent(rest: timeInterval)
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

private extension WorkoutExerciseSetCell {

  func exerciseContent(exercise: WorkoutExercise) -> some View {
    VStack {
      cellHeaderView

      HStack {
        VStack(alignment: .leading) {
          Spacer(minLength: 0)

          if mode == .current || mode == .upNext || isPeeking {
            Image(systemSymbol: exerciseSet.set.systemSymbol)
              .font(.largeTitle)
          }

          Text(exercise.title)
            .font(.title2)
            .bold()

          if mode == .current || isPeeking {
            Text(exercise.summary)
              .fixedSize(horizontal: false, vertical: true)
              .font(.body)
          }

          Spacer(minLength: 0)
        }

        Spacer()

        Text(exercise.measurementDescription)
          .font(.title2)
          .bold()
      }
    }
    .fontDesign(.rounded)
    .foregroundStyle(foregroundColor)
    .cardContainer(fill: mode == .current ? AnyShapeStyle(.tint) : AnyShapeStyle(.background))
    .tint(.green)
  }

  func restContent(rest: TimeInterval) -> some View {
    VStack {
      cellHeaderView

      HStack {
        VStack(alignment: .leading) {
          if mode == .current {
            Image(systemSymbol: .figureStand)
              .font(.largeTitle)
          }
          Text("Rest")
        }

        Spacer()

        Text(DateFormatter.timeIntervalHourMinuteSecondAbbreviated.string(from: DateComponents(second: Int(rest))) ?? "")
      }
      .font(.title2)
      .bold()
    }
    .fontDesign(.rounded)
    .foregroundStyle(foregroundColor)
    .cardContainer(fill: mode == .current ? AnyShapeStyle(.tint) : AnyShapeStyle(.background))
    .tint(.blue)
  }

  var cellHeaderView: some View {
    HStack {
      switch mode {
      case .current:
        Text("Current")
      case .upNext:
        Text("Up Next")
      case .complete:
        Text("Complete")
      default:
        EmptyView()
      }
      Spacer()
      Text("Set \(exerciseSet.setNumber + 1) of \(exerciseSet.set.numberOfSets)")
    }
    .font(.subheadline)
    .foregroundStyle(.secondary)
    .bold()
  }
}

private extension WorkoutExerciseSetCell {

  var foregroundColor: Color {
    switch mode {
    case .current:
      return .black
    case .complete:
      return .secondary
    default:
      return .text
    }
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
          isPeeking: index == peekIndex
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
