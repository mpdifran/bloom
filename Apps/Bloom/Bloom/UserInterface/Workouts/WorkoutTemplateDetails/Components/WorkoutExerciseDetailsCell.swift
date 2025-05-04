//
//  WorkoutExerciseDetailsCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-02.
//

import SwiftUI
import DataContainer

struct WorkoutExerciseDetailsCell: View {
  let exercise: WorkoutExercise

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(exercise.title)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)

        Spacer()

        Text(exercise.measurementDescription)
          .lineLimit(1)
          .fixedSize(horizontal: false, vertical: true)
      }

      Text(exercise.summary)
        .lineLimit(3)
        .foregroundStyle(.secondary)
        .font(.subheadline)
        .fixedSize(horizontal: false, vertical: true)
    }
    .font(.headline)
    .bold()
    .fontDesign(.rounded)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ForEach(WorkoutPlan.Preview.deadlifts.sets ?? []) { set in
        ForEach(set.exercises ?? []) { exercise in
          WorkoutExerciseDetailsCell(exercise: exercise)
            .cardContainer()
        }
      }
    }
  }
}
