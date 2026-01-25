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

  var workoutTypes: [HKWorkoutActivityType] {
    switch self {
    case .cardioEndurance:
      return [
        .walking, .running, .cycling, .rowing, .elliptical,
        .stairClimbing, .stairs, .jumpRope, .mixedCardio, .handCycling,
        .wheelchairRunPace, .wheelchairWalkPace, .stepTraining, .swimBikeRun, .transition, .trackAndField
      ]
    case .strengthConditioning:
      return [
        .traditionalStrengthTraining, .functionalStrengthTraining, .coreTraining,
        .crossTraining, .highIntensityIntervalTraining, .gymnastics
      ]
    case .teamCompetitive:
      return [
        .americanFootball, .australianFootball, .baseball, .basketball, .cricket,
        .handball, .hockey, .lacrosse, .rugby, .soccer, .softball, .volleyball, .waterPolo
      ]
    case .skillPrecision:
      return [
        .archery, .badminton, .bowling, .discSports, .golf, .pickleball,
        .racquetball, .squash, .tableTennis, .tennis
      ]
    case .combat:
      return [
        .boxing, .kickboxing, .martialArts, .wrestling, .fencing
      ]
    case .outdoorAdventure:
      return [
        .climbing, .hiking, .equestrianSports, .fishing, .hunting
      ]
    case .waterSnowIce:
      return [
        .swimming, .downhillSkiing, .snowboarding, .crossCountrySkiing, .curling, .paddleSports, .sailing,
        .skatingSports, .snowSports, .surfingSports, .waterFitness,
        .waterSports, .underwaterDiving
      ]
    case .mindMobilityRecovery:
      return [
        .yoga, .pilates, .barre, .taiChi, .flexibility, .mindAndBody,
        .preparationAndRecovery, .cooldown
      ]
    case .playDanceOther:
      return [
        .cardioDance, .socialDance, .play,
        .fitnessGaming, .other
      ]
    }
  }
}
