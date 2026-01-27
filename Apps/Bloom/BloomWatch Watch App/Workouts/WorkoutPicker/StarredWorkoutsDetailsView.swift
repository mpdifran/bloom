//
//  StarredWorkoutsDetailsView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-27.
//

import SwiftUI
import CoreHealth

struct StarredWorkoutsDetailsView: View {
  let workoutVariants: [WorkoutVariant]
  let pickedWorkout: (WorkoutVariant) -> Void

  var body: some View {
    List {
      ForEach(workoutVariants) { variant in
        WorkoutVariantCell(variant: variant)
          .onTapGesture {
            pickedWorkout(variant)
          }
      }
    }
    .listStyle(.carousel)
  }
}

#Preview {
  PreviewEnvironment {
    StarredWorkoutsDetailsView(
      workoutVariants: [.outdoorRunning, .simple(.cycling), .simple(.swimming)]
    ) { _ in }
  }
}
