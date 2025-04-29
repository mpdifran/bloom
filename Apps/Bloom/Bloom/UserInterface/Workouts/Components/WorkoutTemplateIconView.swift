//
//  WorkoutTemplateIconView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-28.
//

import SwiftUI
import DataContainer
import SFSafeSymbols

struct WorkoutTemplateIconView: View {
  let workoutTemplate: WorkoutTemplate
  let dimension: CGFloat

  init(
    workoutTemplate: WorkoutTemplate,
    dimension: CGFloat = 64
  ) {
    self.workoutTemplate = workoutTemplate
    self.dimension = dimension
  }

  var body: some View {
    Circle()
      .fill(.green)
      .frame(square: dimension)
      .overlay {
        Image(systemSymbol: SFSymbol(rawValue: workoutTemplate.appleWorkoutType.systemImage))
          .font(.system(size: dimension / 2))
          .minimumScaleFactor(0.05)
          .foregroundStyle(.background)
      }
  }
}

#Preview {
  PreviewEnvironment {
    WorkoutTemplateIconView(workoutTemplate: .Preview.deadlifts)
    WorkoutTemplateIconView(
      workoutTemplate: .Preview.deadlifts,
      dimension: 180
    )
  }
}
