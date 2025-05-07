//
//  WorkoutExerciseSetCellHeaderView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-07.
//

import SwiftUI
import DataContainer

struct WorkoutExerciseSetCellHeaderView: View {
  let mode: WorkoutExerciseSetCell.Mode
  let exerciseSet: WorkoutExerciseSet

  var body: some View {
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

#Preview {
  VStack {
    WorkoutExerciseSetCellHeaderView(
      mode: .complete,
      exerciseSet: .Preview.deadlifts
    )
    WorkoutExerciseSetCellHeaderView(
      mode: .current,
      exerciseSet: .Preview.deadlifts
    )
    WorkoutExerciseSetCellHeaderView(
      mode: .upNext,
      exerciseSet: .Preview.deadlifts
    )
    WorkoutExerciseSetCellHeaderView(
      mode: .upcoming,
      exerciseSet: .Preview.deadlifts
    )
  }
}
