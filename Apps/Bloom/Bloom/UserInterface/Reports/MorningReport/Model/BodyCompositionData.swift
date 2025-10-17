//
//  BodyCompositionData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-22.
//

import Foundation
import CoreNetwork

struct BodyCompositionData: SendableNetworkModel {
  let bodyMass: String?
  let bodyMassAverage: String?
  let bodyFatPercentage: String?
  let bodyFatPercentageAverage: String?
  let leanBodyMass: String?
  let leanBodyMassAverage: String?
}