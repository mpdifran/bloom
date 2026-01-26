//
//  WorkoutCategoryDetailsView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-25.
//

import SwiftUI
import HealthKit
import CoreHealth

struct WorkoutCategoryDetailsView: View {
  let workoutCategory: WorkoutCategory
  let pickedWorkout: (WorkoutVariant) -> Void

  @EnvironmentObject var workoutManager: WorkoutManager
  @Environment(\.dismiss) private var dismiss

  @State private var error: Error?

  var body: some View {
    List {
      ForEach(workoutCategory.workoutVariants) { variant in
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
    WorkoutCategoryDetailsView(workoutCategory: .cardioEndurance) { _ in }
  }
}
