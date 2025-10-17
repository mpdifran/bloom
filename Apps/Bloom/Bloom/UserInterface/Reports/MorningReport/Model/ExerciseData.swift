//
//  ExerciseData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-22.
//

import Foundation
import CoreNetwork

struct ExerciseData: SendableNetworkModel {
  let workouts: [WorkoutData]
  let totalExerciseMinutes: String
  let totalCaloriesBurned: String
}

struct WorkoutData: SendableNetworkModel {
  let activityType: String
  let startTime: Date
  let duration: String
  let caloriesBurned: String
  let distance: String?
  let averageHeartRate: String?
  let heartRateZones: HeartRateZoneData?
}

struct HeartRateZoneData: SendableNetworkModel {
  let zone1Minutes: String
  let zone2Minutes: String
  let zone3Minutes: String
  let zone4Minutes: String
  let zone5Minutes: String
}