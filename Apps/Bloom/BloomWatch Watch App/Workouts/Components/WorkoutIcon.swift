//
//  WorkoutIcon.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-25.
//

import SwiftUI
import SFSafeSymbols
import HealthKit
import CoreHealth

struct WorkoutIcon: View {
  let symbol: SFSymbol

  init(symbol: SFSymbol) {
    self.symbol = symbol
  }

  init(workoutType: HKWorkoutActivityType) {
    self.symbol = workoutType.systemSymbol
  }

  var body: some View {
    Circle()
      .fill(.green)
      .overlay {
        Image(systemSymbol: symbol)
          .font(.system(size: 32))
          .foregroundStyle(.black)
      }
      .frame(square: 50)
  }
}

#Preview {
  PreviewEnvironment {
    VStack {
      WorkoutIcon(symbol: .figureRun)
      WorkoutIcon(workoutType: .traditionalStrengthTraining)
    }
  }
}
