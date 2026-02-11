//
//  WorkoutPlanIconView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-28.
//

import SwiftUI
import HealthKit

struct WorkoutPlanIconView: View {
  let workoutTypes: [HKWorkoutActivityType]

  var body: some View {
    switch workoutTypes.count {
    case 3:
      threeIconLayout
    case 2:
      twoIconLayout
    default:
      WorkoutIcon(workoutType: workoutTypes.first ?? .other, scale: .regular)
    }
  }
}

private extension WorkoutPlanIconView {

  var threeIconLayout: some View {
    ZStack {
      WorkoutIcon(workoutType: workoutTypes[0], scale: .small)
        .offset(x: -34)

      WorkoutIcon(workoutType: workoutTypes[2], scale: .small)
        .offset(x: 34)

      WorkoutIcon(workoutType: workoutTypes[1], scale: .regular)
        .shadow(radius: 4)
    }
  }

  var twoIconLayout: some View {
    ZStack {
      WorkoutIcon(workoutType: workoutTypes[1], scale: .regular)
        .offset(x: 20)

      WorkoutIcon(workoutType: workoutTypes[0], scale: .regular)
        .shadow(radius: 4)
        .offset(x: -20)
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      WorkoutPlanIconView(workoutTypes: [
        .traditionalStrengthTraining,
        .running,
        .cycling
      ])

      WorkoutPlanIconView(workoutTypes: [
        .running,
        .cycling
      ])

      WorkoutPlanIconView(workoutTypes: [
        .traditionalStrengthTraining
      ])

      WorkoutPlanIconView(workoutTypes: [
        .running,
        .running,
        .running
      ])
    }
  }
}
