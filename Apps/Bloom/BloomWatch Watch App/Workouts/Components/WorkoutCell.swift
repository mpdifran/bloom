//
//  WorkoutCell.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2025-05-05.
//

import SwiftUI
import HealthKit
import CoreHealth
import SFSafeSymbols
import BloomFoundation

struct WorkoutCell: View {
  let workoutType: HKWorkoutActivityType

  var body: some View {
    HStack(spacing: 10) {
      WorkoutIcon(symbol: workoutType.systemSymbol)

      Text(workoutType.name)
        .font(.title3)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.white)
        .multilineTextAlignment(.leading)
        .lineLimit(4)
    }
    .padding(.vertical, 20)
    .foregroundStyle(.mutedGreen)
    .selectable()
  }
}

private extension WorkoutCell {

  var listRowBackground: some View {
    RoundedRectangle(cornerRadius: 20)
      .fill(.background.secondary)
  }
}

#Preview {
  List {
    WorkoutCell(workoutType: .cycling)
    WorkoutCell(workoutType: .running)
    WorkoutCell(workoutType: .climbing)
    WorkoutCell(workoutType: .highIntensityIntervalTraining)
  }
  .listStyle(.carousel)
}
