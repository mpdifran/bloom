//
//  TrainingLoadData.swift
//  Bloom
//
//  Created by Assistant on 2025-01-25.
//

import Foundation

struct TrainingLoadData: SendableNetworkModel {
  let workoutEffortScores: [WorkoutEffortData]
  let percentageDifference: String?
  let trainingLoadStatus: String? // Well Above, Above, Steady, Below, Well Below
}

struct WorkoutEffortData: SendableNetworkModel {
  let workoutType: String
  let startTime: Date
  let duration: String
  let userEffortScore: String?
  let estimatedEffortScore: String?
  let effortLevel: String? // Easy, Moderate, Hard, All Out
}