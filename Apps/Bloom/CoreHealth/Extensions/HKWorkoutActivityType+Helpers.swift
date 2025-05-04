//
//  HKWorkoutActivityType+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-20.
//

import Foundation
import HealthKit

public extension HKWorkoutActivityType {

  var name: String {
    switch self {
    case .americanFootball: return "American Football"
    case .archery: return "Archery"
    case .australianFootball: return "Australian Football"
    case .badminton: return "Badminton"
    case .baseball: return "Baseball"
    case .basketball: return "Basketball"
    case .bowling: return "Bowling"
    case .boxing: return "Boxing"
    case .climbing: return "Climbing"
    case .cricket: return "Cricket"
    case .crossTraining: return "Cross Training"
    case .curling: return "Curling"
    case .cycling: return "Cycling"
    case .dance: return "Dance"
    case .danceInspiredTraining: return "Dance Inspired Training"
    case .elliptical: return "Elliptical"
    case .equestrianSports: return "Equestrian Sports"
    case .fencing: return "Fencing"
    case .fishing: return "Fishing"
    case .functionalStrengthTraining: return "Functional Strength Training"
    case .golf: return "Golf"
    case .gymnastics: return "Gymnastics"
    case .handball: return "Handball"
    case .hiking: return "Hiking"
    case .hockey: return "Hockey"
    case .hunting: return "Hunting"
    case .lacrosse: return "Lacrosse"
    case .martialArts: return "Martial Arts"
    case .mindAndBody: return "Mind and Body"
    case .paddleSports: return "Paddle Sports"
    case .play: return "Play"
    case .preparationAndRecovery: return "Preparation and Recovery"
    case .racquetball: return "Racquetball"
    case .rowing: return "Rowing"
    case .rugby: return "Rugby"
    case .running: return "Running"
    case .sailing: return "Sailing"
    case .skatingSports: return "Skating Sports"
    case .snowSports: return "Snow Sports"
    case .soccer: return "Soccer"
    case .softball: return "Softball"
    case .squash: return "Squash"
    case .stairClimbing: return "Stair Climbing"
    case .surfingSports: return "Surfing Sports"
    case .swimming: return "Swimming"
    case .tableTennis: return "Table Tennis"
    case .tennis: return "Tennis"
    case .trackAndField: return "Track and Field"
    case .traditionalStrengthTraining: return "Traditional Strength Training"
    case .volleyball: return "Volleyball"
    case .walking: return "Walking"
    case .waterFitness: return "Water Fitness"
    case .waterPolo: return "Water Polo"
    case .waterSports: return "Water Sports"
    case .wrestling: return "Wrestling"
    case .yoga: return "Yoga"
    case .barre: return "Barre"
    case .coreTraining: return "Core Training"
    case .crossCountrySkiing: return "Cross Country Skiing"
    case .downhillSkiing: return "Downhill Skiing"
    case .flexibility: return "Flexibility"
    case .highIntensityIntervalTraining: return "High Intensity Interval Training"
    case .jumpRope: return "Jump Rope"
    case .kickboxing: return "Kickboxing"
    case .pilates: return "Pilates"
    case .snowboarding: return "Snowboarding"
    case .stairs: return "Stairs"
    case .stepTraining: return "Step Training"
    case .wheelchairWalkPace: return "Wheelchair Walk Pace"
    case .wheelchairRunPace: return "Wheelchair Run Pace"
    case .taiChi: return "Tai Chi"
    case .mixedCardio: return "Mixed Cardio"
    case .handCycling: return "Hand Cycling"
    case .discSports: return "Disc Sports"
    case .fitnessGaming: return "Fitness Gaming"
    case .mixedMetabolicCardioTraining: return "Mixed Metabolic Cardio Training"
    case .cardioDance: return "Cardio Dance"
    case .socialDance: return "Social Dance"
    case .pickleball: return "Picklebal"
    case .cooldown: return "Cooldown"
    case .swimBikeRun: return "Swim Bike Run"
    case .transition: return "Transition"
    case .underwaterDiving: return "Underwater Diving"
    case .other: return "Other"
    @unknown default: return "Other"
    }
  }

  var systemImage: String {
    switch self {
    case .americanFootball:
      "figure.american.football"
    case .archery:
      "figure.archery"
    case .australianFootball:
      "figure.australian.football"
    case .badminton:
      "figure.badminton"
    case .baseball:
      "figure.baseball"
    case .basketball:
      "figure.basketball"
    case .bowling:
      "figure.bowling"
    case .boxing:
      "figure.boxing"
    case .climbing:
      "figure.climbing"
    case .cricket:
      "figure.cricket"
    case .crossTraining:
      "figure.cross.training"
    case .curling:
      "figure.curling"
    case .cycling:
      "figure.outdoor.cycle"
    case .dance:
      "figure.dance"
    case .danceInspiredTraining:
      "figure.socialdance"
    case .elliptical:
      "figure.elliptical"
    case .equestrianSports:
      "figure.equestrian.sports"
    case .fencing:
      "figure.fencing"
    case .fishing:
      "figure.fishing"
    case .functionalStrengthTraining:
      "figure.strengthtraining.functional"
    case .golf:
      "figure.golf"
    case .gymnastics:
      "figure.gymnastics"
    case .handball:
      "figure.handball"
    case .hiking:
      "figure.hiking"
    case .hockey:
      "figure.hockey"
    case .hunting:
      "figure.hunting"
    case .lacrosse:
      "figure.lacrosse"
    case .martialArts:
      "figure.martial.arts"
    case .mindAndBody:
      "figure.mind.and.body"
    case .mixedMetabolicCardioTraining:
      "figure.mixed.cardio"
    case .paddleSports:
      "figure.pickleball"
    case .play:
      "figure.play"
    case .preparationAndRecovery:
      "figure.cooldown"
//      "figure.mind.and.body"
    case .racquetball:
      "figure.racquetball"
    case .rowing:
      "figure.rower"
    case .rugby:
      "figure.rugby"
    case .running:
      "figure.run"
    case .sailing:
      "figure.sailing"
    case .skatingSports:
      "figure.skating"
    case .snowSports:
      "figure.snowboarding"
    case .soccer:
      "figure.soccer"
    case .softball:
      "figure.softball"
    case .squash:
      "figure.squash"
    case .stairClimbing:
      "figure.stair.stepper"
    case .surfingSports:
      "figure.surfing"
    case .swimming:
      "figure.pool.swim"
    case .tableTennis:
      "figure.table.tennis"
    case .tennis:
      "figure.tennis"
    case .trackAndField:
      "figure.track.and.field"
    case .traditionalStrengthTraining:
      "figure.strengthtraining.traditional"
    case .volleyball:
      "figure.volleyball"
    case .walking:
      "figure.walk"
    case .waterFitness:
      "figure.water.fitness"
    case .waterPolo:
      "figure.waterpolo"
    case .waterSports:
      "figure.waterpolo"
    case .wrestling:
      "figure.wrestling"
    case .yoga:
      "figure.yoga"
    case .barre:
      "figure.barre"
    case .coreTraining:
      "figure.core.training"
    case .crossCountrySkiing:
      "figure.skiing.crosscountry"
    case .downhillSkiing:
      "figure.skiing.downhill"
    case .flexibility:
      "figure.flexibility"
    case .highIntensityIntervalTraining:
      "figure.highintensity.intervaltraining"
    case .jumpRope:
      "figure.jumprope"
    case .kickboxing:
      "figure.kickboxing"
    case .pilates:
      "figure.pilates"
    case .snowboarding:
      "figure.snowboarding"
    case .stairs:
      "figure.stairs"
    case .stepTraining:
      "figure.step.training"
    case .wheelchairWalkPace:
      "figure.roll"
    case .wheelchairRunPace:
      "figure.roll.runningpace"
    case .taiChi:
      "figure.taichi"
    case .mixedCardio:
      "figure.mixed.cardio"
    case .handCycling:
      "figure.hand.cycling"
    case .discSports:
      "figure.disc.sports"
    case .fitnessGaming:
      "gamecontroller"
    case .cardioDance:
      "figure.dance"
    case .socialDance:
      "figure.socialdance"
    case .pickleball:
      "figure.pickleball"
    case .cooldown:
      "figure.cooldown"
    case .swimBikeRun:
      "figure.run.circle"
    case .transition:
      "arrow.up.arrow.down"
    case .underwaterDiving:
      "water.waves.and.arrow.down"
    case .other:
      "figure.run"
    @unknown default:
      "figure.run"
    }
  }
}

public extension Array where Element == HKWorkoutActivityType {
  static let mobilityAndFlexibilityTypes: [HKWorkoutActivityType] = [
    .barre, .yoga, .pilates, .flexibility, .mindAndBody, .taiChi
  ]
  static let strengthTrainingTypes: [HKWorkoutActivityType] = [
    .traditionalStrengthTraining, .functionalStrengthTraining, .coreTraining
  ]
  static let cardioTypes: [HKWorkoutActivityType] = [
    .boxing, .crossTraining, .cycling, .elliptical, .highIntensityIntervalTraining, .jumpRope, .kickboxing, .mixedCardio, .rowing, .running, .stairClimbing, .stepTraining, .swimming, .tennis, .trackAndField, .walking, .waterFitness, .wheelchairRunPace, .wheelchairWalkPace, .cardioDance, .socialDance, .fitnessGaming, .handCycling
  ]
  static let highIntensityIntervalTrainingTypes: [HKWorkoutActivityType] = [
    .highIntensityIntervalTraining, .crossTraining, .mixedCardio, .jumpRope, .kickboxing, .boxing, .stepTraining
  ]
}
