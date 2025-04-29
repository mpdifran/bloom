//
//  WorkoutTemplateIconView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-28.
//

import SwiftUI
import DataContainer
import SFSafeSymbols
import HealthKit

struct WorkoutTemplateIconView: View {
  let workoutType: HKWorkoutActivityType
  let dimension: CGFloat

  init(
    workoutType: HKWorkoutActivityType,
    dimension: CGFloat = 64
  ) {
    self.workoutType = workoutType
    self.dimension = dimension
  }

  var body: some View {
    Circle()
      .fill(.green)
      .frame(square: dimension)
      .overlay {
        Image(systemSymbol: SFSymbol(rawValue: workoutType.systemImage))
          .font(.system(size: dimension / 2))
          .minimumScaleFactor(0.05)
          .foregroundStyle(.background)
      }
  }
}

#Preview {
  PreviewEnvironment {
    WorkoutTemplateIconView(workoutType: .traditionalStrengthTraining)
    WorkoutTemplateIconView(
      workoutType: .running,
      dimension: 180
    )
  }
}
