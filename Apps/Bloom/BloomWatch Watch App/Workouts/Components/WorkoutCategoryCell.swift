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
  let workoutVariants: [WorkoutVariant]

  private var displayedVariants: [WorkoutVariant] {
    Array(workoutVariants.prefix(5))
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      GeometryReader { geometry in
        let iconCount = displayedVariants.count
        let spacing = geometry.size.width / CGFloat(iconCount + 1)

        ZStack(alignment: .leading) {
          ForEach(Array(displayedVariants.reversed().enumerated()), id: \.offset) { index, variant in
            WorkoutIcon(symbol: variant.symbol)
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
        workoutVariants: [
          .simple(.highIntensityIntervalTraining),
          .outdoorRunning,
          .simple(.functionalStrengthTraining),
          .simple(.traditionalStrengthTraining),
          .simple(.crossTraining)
        ]
      )
    }
  }
}
