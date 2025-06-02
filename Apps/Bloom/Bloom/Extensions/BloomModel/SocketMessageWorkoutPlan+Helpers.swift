//
//  SocketMessageWorkoutPlan+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-06-02.
//

import SwiftUI
import BloomModel
import CoreHealth

extension SocketMessage.WorkoutPlan.Equipment {

  var image: ImageResource {
    switch self {
    case .dumbbells:
      return .dumbbells
    case .barbell:
      return .barbell
    case .kettlebell:
      return .kettlebell
    case .batBell:
      return .batbell
    case .chinUpBar:
      return .chinUpBar
    case .treadmill:
      return .treadmill
    case .stationaryBike:
      return .stationaryBike
    case .bike:
      return .bike
    case .elliptical:
      return .elliptical
    case .rowingMachine:
      return .rowingMachine
    case .skiMachine:
      return .skiMachine
    case .yogaMat:
      return .yogaMat
    case .resistanceBand:
      return .resistanceBand
    case .weightedVest:
      return .weightedVest
    }
  }
}
