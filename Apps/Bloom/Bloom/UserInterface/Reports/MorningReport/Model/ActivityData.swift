//
//  ActivityData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-22.
//

import Foundation
import CoreNetwork

struct ActivityData: SendableNetworkModel {
  let basalEnergyBurned: MetricWithTrend
  let activeEnergyBurned: MetricWithTrend
  let totalEnergyBurned: MetricWithTrend
  let steps: MetricWithTrend?
  let walkingDistance: MetricWithTrend?
  let timeInDaylight: MetricWithTrend?
}
