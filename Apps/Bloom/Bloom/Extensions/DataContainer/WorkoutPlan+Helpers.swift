//
//  WorkoutPlan+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-03.
//

import DataContainer
import SFSafeSymbols

extension WorkoutPlan {

  var representativeSystemSymbol: SFSymbol {
    SFSymbol(rawValue: representativeAppleWorkoutType.systemImage)
  }
}
