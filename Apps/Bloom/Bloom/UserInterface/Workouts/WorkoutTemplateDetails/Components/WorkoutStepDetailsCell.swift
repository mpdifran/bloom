//
//  WorkoutStepDetailsCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-30.
//

import SwiftUI
import DataContainer
import HealthKit
import SFSafeSymbols

struct WorkoutStepDetailsCell: View {
  let rootActivityType: HKWorkoutActivityType
  let step: WorkoutStep

  var body: some View {
    HStack {
      Image(systemSymbol: symbol)
        .foregroundStyle(.green)
        .font(.largeTitle)
        .frame(width: 60)

      VStack(alignment: .leading) {
        Text(step.title)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)

        Text(step.parameterDescription)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer()
    }
    .cardContainer()
  }
}

private extension WorkoutStepDetailsCell {

  var symbol: SFSymbol {
    if step.kind == .rest {
      return SFSymbol.figureStand
    }
    if let activityType = step.overrideAppleWorkoutType {
      return SFSymbol(rawValue: activityType.systemImage)
    }
    return SFSymbol(rawValue: rootActivityType.systemImage)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ForEach(WorkoutTemplate.Preview.deadlifts.steps ?? []) { step in
        WorkoutStepDetailsCell(
          rootActivityType: .traditionalStrengthTraining,
          step: step
        )
      }
    }
  }
}
