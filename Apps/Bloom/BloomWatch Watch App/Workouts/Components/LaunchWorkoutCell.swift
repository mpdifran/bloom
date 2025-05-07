//
//  LaunchWorkoutCell.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2025-05-05.
//

import SwiftUI
import HealthKit
import CoreHealth
import SFSafeSymbols
import BloomFoundation

struct LaunchWorkoutCell: View {
  let workoutType: HKWorkoutActivityType

  var body: some View {
    VStack(alignment: .leading) {
      Image(systemSymbol: SFSymbol(rawValue: workoutType.systemImage))
        .font(.largeTitle)
      Text(workoutType.name)
        .font(.headline)
        .bold()
        .fontDesign(.rounded)
    }
    .padding(8)
    .foregroundStyle(.black)
    .listRowBackground(listRowBackground)
    .selectable()
  }
}

private extension LaunchWorkoutCell {

  var listRowBackground: some View {
    RoundedRectangle(cornerRadius: 20)
      .fill(.green)
  }
}

#Preview {
  List {
    LaunchWorkoutCell(workoutType: .cycling)
    LaunchWorkoutCell(workoutType: .running)
    LaunchWorkoutCell(workoutType: .climbing)
    LaunchWorkoutCell(workoutType: .highIntensityIntervalTraining)
  }
  .listStyle(.carousel)
}
