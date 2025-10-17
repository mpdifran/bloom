//
//  StressData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-22.
//

import Foundation
import CoreNetwork

struct StressData: SendableNetworkModel {
  let heartRateVariability: String?
  let bloodPressure: BloodPressureData?
}

struct BloodPressureData: SendableNetworkModel {
  let systolic: String
  let diastolic: String
  let date: Date
}