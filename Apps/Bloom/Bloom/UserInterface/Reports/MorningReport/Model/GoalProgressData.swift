//
//  GoalProgressData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-22.
//

import Foundation

struct GoalProgressData: SendableNetworkModel {
  let date: Date
  let goalProgress: [GoalProgress]
}

struct GoalProgress: SendableNetworkModel {
  let metric: String
  let timePeriod: String
  let goalValue: String
  let currentValue: String
  let progressMadeYesterdayValue: String
  let progressPercentage: Double
  let progressMadeYesterdayPercentage: Double
  let goalMet: Bool
}
