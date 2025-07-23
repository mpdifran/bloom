//
//  ActivityData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-22.
//

import Foundation

struct ActivityData: SendableNetworkModel {
  let basalEnergyBurned: String
  let activeEnergyBurned: String
  let totalEnergyBurned: String
  let steps: String?
  let walkingDistance: String?
  let timeInDaylight: String?
}