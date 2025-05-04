//
//  WorkoutSet+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-30.
//

import DataContainer
import SFSafeSymbols

extension WorkoutSet {

  var systemSymbol: SFSymbol {
    SFSymbol(rawValue: appleWorkoutType.systemImage)
  }
}
