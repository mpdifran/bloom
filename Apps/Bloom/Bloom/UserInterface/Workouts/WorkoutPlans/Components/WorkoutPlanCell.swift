//
//  WorkoutPlanCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-28.
//

import SwiftUI
import DataContainer
import SFSafeSymbols

struct WorkoutPlanCell: View {
  let workoutPlan: WorkoutPlan

  var body: some View {
    VStack {
      WorkoutPlanIconView(workoutTypes: workoutPlan.displayWorkoutTypes)

      Text(workoutPlan.title)
        .font(.subheadline)
        .bold()
        .fontDesign(.rounded)
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.center)
        .lineLimit(2)

      Text(workoutPlan.durationDescription)
        .foregroundStyle(.secondary)
        .font(.caption)
        .lineLimit(2)
    }
    .frame(maxWidth: .infinity)
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      WorkoutPlanCell(workoutPlan: .Preview.deadlifts)
    }
  }
}
