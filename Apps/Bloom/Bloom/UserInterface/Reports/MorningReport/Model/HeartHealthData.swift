//
//  HeartHealthData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-22.
//

import Foundation
import CoreNetwork

struct HeartHealthData: SendableNetworkModel {
  let vo2Max: String?
  let restingHeartRate: String?
  let heartRateRecovery: String?
  let heartRateVariability: String?
}