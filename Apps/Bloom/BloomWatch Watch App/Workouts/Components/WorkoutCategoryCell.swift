//
//  WorkoutCategoryCell.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-25.
//

import SwiftUI
import SFSafeSymbols
import HealthKit

struct WorkoutCategoryCell: View {
  let title: String
  let workoutTypes: [HKWorkoutActivityType]

  private var displayedTypes: [HKWorkoutActivityType] {
    Array(workoutTypes.prefix(5))
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      GeometryReader { geometry in
        let iconCount = displayedTypes.count
        let spacing = geometry.size.width / CGFloat(iconCount + 1)

        ZStack(alignment: .leading) {
          ForEach(Array(displayedTypes.reversed().enumerated()), id: \.offset) { index, type in
            WorkoutIcon(workoutType: type)
              .shadow(radius: 10)
              .position(x: spacing * CGFloat(iconCount - index), y: geometry.size.height / 2)
          }
        }
      }
      .frame(height: 60)

      Text(title)
        .font(.title3)
        .bold()
    }
    .padding(.vertical, 20)
    .selectable()
  }
}

#Preview {
  PreviewEnvironment {
    List {
      WorkoutCategoryCell(
        title: "Strength & Conditioning",
        workoutTypes: [
          .highIntensityIntervalTraining,
          .running,
          .functionalStrengthTraining,
          .traditionalStrengthTraining,
          .crossTraining
        ]
      )
    }
  }
}
