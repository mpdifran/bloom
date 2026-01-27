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

extension WorkoutIcon {
  enum Scale {
    case regular
    case small
  }
}

struct WorkoutIcon: View {
  let symbol: SFSymbol
  let scale: Scale

  init(
    symbol: SFSymbol,
    scale: Scale = .regular
  ) {
    self.symbol = symbol
    self.scale = scale
  }

  init(
    workoutType: HKWorkoutActivityType,
    scale: Scale = .regular
  ) {
    self.symbol = workoutType.systemSymbol
    self.scale = scale
  }

  var body: some View {
    Circle()
      .fill(.green)
      .overlay {
        Image(systemSymbol: symbol)
          .font(.system(size: iconFontSize))
          .foregroundStyle(.black)
      }
      .frame(square: circleDimension)
  }
}

private extension WorkoutIcon {

  var iconFontSize: CGFloat {
    switch scale {
    case .regular:
      return 32
    case .small:
      return 20
    }
  }

  var circleDimension: CGFloat {
    switch scale {
    case .regular:
      return 50
    case .small:
      return 30
    }
  }
}

#Preview {
  PreviewEnvironment {
    VStack {
      WorkoutIcon(symbol: .figureRun)
      WorkoutIcon(symbol: .figureWalk, scale: .small)
      WorkoutIcon(workoutType: .traditionalStrengthTraining)
    }
  }
}
