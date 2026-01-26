//
//  WorkoutCategory.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-25.
//

import SwiftUI
import HealthKit

// MARK: - Workout Category

enum WorkoutCategory: String, CaseIterable, Identifiable {
  case cardioEndurance = "Cardio & Endurance"
  case strengthConditioning = "Strength & Conditioning"
  case teamCompetitive = "Team & Competitive Sports"
  case skillPrecision = "Skill & Precision Sports"
  case combat = "Combat Sports"
  case outdoorAdventure = "Outdoor & Adventure"
  case waterSnowIce = "Water, Snow & Ice"
  case mindMobilityRecovery = "Mind, Mobility & Recovery"
  case playDanceOther = "Play, Dance & Other"

  var id: String { rawValue }

  var workoutVariants: [WorkoutVariant] {
    switch self {
    case .cardioEndurance:
      return [
        .outdoorWalking, .indoorWalking,
        .outdoorRunning, .indoorRunning,
        .outdoorCycling, .indoorCycling,
        .outdoorRowing, .indoorRowing,
        .simple(.elliptical),
        .simple(.stairClimbing),
        .simple(.stairs),
        .simple(.jumpRope),
        .simple(.mixedCardio),
        .simple(.handCycling),
        .simple(.wheelchairRunPace),
        .simple(.wheelchairWalkPace),
        .simple(.stepTraining),
        .simple(.swimBikeRun),
        .simple(.transition),
        .simple(.trackAndField)
      ]
    case .strengthConditioning:
      return [
        .simple(.traditionalStrengthTraining),
        .simple(.functionalStrengthTraining),
        .simple(.coreTraining),
        .simple(.crossTraining),
        .simple(.highIntensityIntervalTraining),
        .simple(.gymnastics)
      ]
    case .teamCompetitive:
      return [
        .simple(.americanFootball),
        .simple(.australianFootball),
        .simple(.baseball),
        .simple(.basketball),
        .simple(.cricket),
        .simple(.handball),
        .indoorHockey, .outdoorHockey,
        .simple(.lacrosse),
        .simple(.rugby),
        .outdoorSoccer, .indoorSoccer,
        .simple(.softball),
        .simple(.volleyball),
        .simple(.waterPolo)
      ]
    case .skillPrecision:
      return [
        .simple(.archery),
        .simple(.badminton),
        .simple(.bowling),
        .simple(.discSports),
        .simple(.golf),
        .simple(.pickleball),
        .simple(.racquetball),
        .simple(.squash),
        .simple(.tableTennis),
        .simple(.tennis)
      ]
    case .combat:
      return [
        .simple(.boxing),
        .simple(.kickboxing),
        .simple(.martialArts),
        .simple(.wrestling),
        .simple(.fencing)
      ]
    case .outdoorAdventure:
      return [
        .simple(.climbing),
        .simple(.hiking),
        .simple(.equestrianSports),
        .simple(.fishing),
        .simple(.hunting)
      ]
    case .waterSnowIce:
      return [
        .poolSwimming, .openWaterSwimming,
        .simple(.downhillSkiing),
        .simple(.snowboarding),
        .simple(.crossCountrySkiing),
        .simple(.curling),
        .simple(.paddleSports),
        .simple(.sailing),
        .indoorSkating, .outdoorSkating,
        .simple(.snowSports),
        .simple(.surfingSports),
        .simple(.waterFitness),
        .simple(.waterSports),
        .simple(.underwaterDiving)
      ]
    case .mindMobilityRecovery:
      return [
        .simple(.yoga),
        .simple(.pilates),
        .simple(.barre),
        .simple(.taiChi),
        .simple(.flexibility),
        .simple(.mindAndBody),
        .simple(.preparationAndRecovery),
        .simple(.cooldown)
      ]
    case .playDanceOther:
      return [
        .simple(.cardioDance),
        .simple(.socialDance),
        .simple(.play),
        .simple(.fitnessGaming),
        .simple(.other)
      ]
    }
  }
}
