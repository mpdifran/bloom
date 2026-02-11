//
//  WorkoutIcon.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-02-10.
//

import SwiftUI
import SFSafeSymbols
import HealthKit
import CoreHealth

extension WorkoutIcon {
  enum Scale {
    case large
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
      .fill(.blue.gradient)
      .overlay {
        Image(systemSymbol: symbol)
          .font(.system(size: iconFontSize))
          .foregroundStyle(.black)
      }
      .frame(square: circleDimension)
      .compositingGroup()
  }
}

private extension WorkoutIcon {

  var iconFontSize: CGFloat {
    switch scale {
    case .large:
      return 60
    case .regular:
      return 28
    case .small:
      return 22
    }
  }

  var circleDimension: CGFloat {
    switch scale {
    case .large:
      return 130
    case .regular:
      return 60
    case .small:
      return 50
    }
  }
}

#Preview {
  PreviewEnvironment {
    VStack {
      WorkoutIcon(symbol: .figureRun, scale: .large)
      WorkoutIcon(symbol: .figureRun)
      WorkoutIcon(symbol: .figureWalk, scale: .small)
      WorkoutIcon(workoutType: .traditionalStrengthTraining)
    }
  }
}
