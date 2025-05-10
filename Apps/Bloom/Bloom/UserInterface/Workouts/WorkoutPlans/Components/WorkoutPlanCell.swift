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
    HStack(spacing: 20) {
      WorkoutPlanIconView(workoutType: workoutPlan.representativeAppleWorkoutType)

      VStack(alignment: .leading) {
        Text(workoutPlan.title)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)
          .fixedSize(horizontal: false, vertical: true)
          .multilineTextAlignment(.leading)
          .lineLimit(2)

        Text(workoutPlan.durationDescription)
          .foregroundStyle(.secondary)
          .font(.subheadline)
          .lineLimit(2)
      }

      Spacer()

      DisclosureIndicator()
    }
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
