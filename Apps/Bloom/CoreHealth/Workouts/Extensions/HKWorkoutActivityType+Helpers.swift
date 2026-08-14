//
//  HKWorkoutActivityType+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-20.
//

import Foundation
import HealthKit
import SFSafeSymbols

public extension HKWorkoutActivityType {

  /// Stable English name, used for logging, analytics and anything sent to the backend.
  /// Never localized — `name` is the display-facing counterpart.
  var canonicalName: String {
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
    case .paddleSports: return "Paddling"
    case .play: return "Play"
    case .preparationAndRecovery: return "Preparation and Recovery"
    case .racquetball: return "Racquetball"
    case .rowing: return "Rowing"
    case .rugby: return "Rugby"
    case .running: return "Run"
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
    case .walking: return "Walk"
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

  var name: String {
    switch self {
    case .americanFootball: return String(localized: "American Football", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .archery: return String(localized: "Archery", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .australianFootball: return String(localized: "Australian Football", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .badminton: return String(localized: "Badminton", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .baseball: return String(localized: "Baseball", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .basketball: return String(localized: "Basketball", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .bowling: return String(localized: "Bowling", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .boxing: return String(localized: "Boxing", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .climbing: return String(localized: "Climbing", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .cricket: return String(localized: "Cricket", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .crossTraining: return String(localized: "Cross Training", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .curling: return String(localized: "Curling", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .cycling: return String(localized: "Cycling", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .dance: return String(localized: "Dance", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .danceInspiredTraining: return String(localized: "Dance Inspired Training", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .elliptical: return String(localized: "Elliptical", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .equestrianSports: return String(localized: "Equestrian Sports", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .fencing: return String(localized: "Fencing", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .fishing: return String(localized: "Fishing", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .functionalStrengthTraining: return String(localized: "Functional Strength Training", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .golf: return String(localized: "Golf", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .gymnastics: return String(localized: "Gymnastics", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .handball: return String(localized: "Handball", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .hiking: return String(localized: "Hiking", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .hockey: return String(localized: "Hockey", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .hunting: return String(localized: "Hunting", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .lacrosse: return String(localized: "Lacrosse", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .martialArts: return String(localized: "Martial Arts", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .mindAndBody: return String(localized: "Mind and Body", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .paddleSports: return String(localized: "Paddling", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .play: return String(localized: "Play", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .preparationAndRecovery: return String(localized: "Preparation and Recovery", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .racquetball: return String(localized: "Racquetball", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .rowing: return String(localized: "Rowing", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .rugby: return String(localized: "Rugby", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .running: return String(localized: "Run", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .sailing: return String(localized: "Sailing", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .skatingSports: return String(localized: "Skating Sports", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .snowSports: return String(localized: "Snow Sports", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .soccer: return String(localized: "Soccer", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .softball: return String(localized: "Softball", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .squash: return String(localized: "Squash", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .stairClimbing: return String(localized: "Stair Climbing", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .surfingSports: return String(localized: "Surfing Sports", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .swimming: return String(localized: "Swimming", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .tableTennis: return String(localized: "Table Tennis", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .tennis: return String(localized: "Tennis", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .trackAndField: return String(localized: "Track and Field", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .traditionalStrengthTraining: return String(localized: "Traditional Strength Training", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .volleyball: return String(localized: "Volleyball", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .walking: return String(localized: "Walk", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .waterFitness: return String(localized: "Water Fitness", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .waterPolo: return String(localized: "Water Polo", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .waterSports: return String(localized: "Water Sports", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .wrestling: return String(localized: "Wrestling", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .yoga: return String(localized: "Yoga", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .barre: return String(localized: "Barre", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .coreTraining: return String(localized: "Core Training", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .crossCountrySkiing: return String(localized: "Cross Country Skiing", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .downhillSkiing: return String(localized: "Downhill Skiing", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .flexibility: return String(localized: "Flexibility", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .highIntensityIntervalTraining: return String(localized: "High Intensity Interval Training", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .jumpRope: return String(localized: "Jump Rope", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .kickboxing: return String(localized: "Kickboxing", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .pilates: return String(localized: "Pilates", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .snowboarding: return String(localized: "Snowboarding", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .stairs: return String(localized: "Stairs", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .stepTraining: return String(localized: "Step Training", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .wheelchairWalkPace: return String(localized: "Wheelchair Walk Pace", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .wheelchairRunPace: return String(localized: "Wheelchair Run Pace", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .taiChi: return String(localized: "Tai Chi", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .mixedCardio: return String(localized: "Mixed Cardio", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .handCycling: return String(localized: "Hand Cycling", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .discSports: return String(localized: "Disc Sports", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .fitnessGaming: return String(localized: "Fitness Gaming", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .mixedMetabolicCardioTraining: return String(localized: "Mixed Metabolic Cardio Training", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .cardioDance: return String(localized: "Cardio Dance", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .socialDance: return String(localized: "Social Dance", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .pickleball: return String(localized: "Picklebal", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .cooldown: return String(localized: "Cooldown", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .swimBikeRun: return String(localized: "Swim Bike Run", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .transition: return String(localized: "Transition", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .underwaterDiving: return String(localized: "Underwater Diving", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    case .other: return String(localized: "Other", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
    @unknown default: return String(localized: "Other", bundle: Bundle.coreHealth, comment: "Display name for workout activity type")
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
      "oar.2.crossed"
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
      "chevron.right.2"
    @unknown default:
      "chevron.right.2"
    }
  }

  var systemSymbol: SFSymbol {
    switch self {
    case .americanFootball:
        .figureAmericanFootball
    case .archery:
        .figureArchery
    case .australianFootball:
        .figureAustralianFootball
    case .badminton:
        .figureBadminton
    case .baseball:
        .figureBaseball
    case .basketball:
        .figureBasketball
    case .bowling:
        .figureBowling
    case .boxing:
        .figureBoxing
    case .climbing:
        .figureClimbing
    case .cricket:
        .figureCricket
    case .crossTraining:
        .figureCrossTraining
    case .curling:
        .figureCurling
    case .cycling:
        .figureOutdoorCycle
    case .dance:
        .figureDance
    case .danceInspiredTraining:
        .figureSocialdance
    case .elliptical:
        .figureElliptical
    case .equestrianSports:
        .figureEquestrianSports
    case .fencing:
        .figureFencing
    case .fishing:
        .figureFishing
    case .functionalStrengthTraining:
        .figureStrengthtrainingFunctional
    case .golf:
        .figureGolf
    case .gymnastics:
        .figureGymnastics
    case .handball:
        .figureHandball
    case .hiking:
        .figureHiking
    case .hockey:
        .figureHockey
    case .hunting:
        .figureHunting
    case .lacrosse:
        .figureLacrosse
    case .martialArts:
        .figureMartialArts
    case .mindAndBody:
        .figureMindAndBody
    case .mixedMetabolicCardioTraining:
        .figureMixedCardio
    case .paddleSports:
        .oar2Crossed
    case .play:
        .figurePlay
    case .preparationAndRecovery:
        .figureCooldown
    case .racquetball:
        .figureRacquetball
    case .rowing:
        .figureIndoorRowing
    case .rugby:
        .figureRugby
    case .running:
        .figureRun
    case .sailing:
        .figureSailing
    case .skatingSports:
        .figureIceSkating
    case .snowSports:
        .figureSnowboarding
    case .soccer:
        .figureIndoorSoccer
    case .softball:
        .figureSoftball
    case .squash:
        .figureSquash
    case .stairClimbing:
        .figureStairStepper
    case .surfingSports:
        .figureSurfing
    case .swimming:
        .figurePoolSwim
    case .tableTennis:
        .figureTableTennis
    case .tennis:
        .figureTennis
    case .trackAndField:
        .figureTrackAndField
    case .traditionalStrengthTraining:
        .figureStrengthtrainingTraditional
    case .volleyball:
        .figureVolleyball
    case .walking:
        .figureWalk
    case .waterFitness:
        .figureWaterFitness
    case .waterPolo:
        .figureWaterpolo
    case .waterSports:
        .figureWaterpolo
    case .wrestling:
        .figureWrestling
    case .yoga:
        .figureYoga
    case .barre:
        .figureBarre
    case .coreTraining:
        .figureCoreTraining
    case .crossCountrySkiing:
        .figureSkiingCrosscountry
    case .downhillSkiing:
        .figureSkiingDownhill
    case .flexibility:
        .figureFlexibility
    case .highIntensityIntervalTraining:
        .figureHighintensityIntervaltraining
    case .jumpRope:
        .figureJumprope
    case .kickboxing:
        .figureKickboxing
    case .pilates:
        .figurePilates
    case .snowboarding:
        .figureSnowboarding
    case .stairs:
        .figureStairs
    case .stepTraining:
        .figureStepTraining
    case .wheelchairWalkPace:
        .figureRoll
    case .wheelchairRunPace:
        .figureRollRunningpace
    case .taiChi:
        .figureTaichi
    case .mixedCardio:
        .figureMixedCardio
    case .handCycling:
        .figureHandCycling
    case .discSports:
        .figureDiscSports
    case .fitnessGaming:
        .gamecontroller
    case .cardioDance:
        .figureDance
    case .socialDance:
        .figureSocialdance
    case .pickleball:
        .figurePickleball
    case .cooldown:
        .figureCooldown
    case .swimBikeRun:
        .figureRunCircle
    case .transition:
        .arrowUpArrowDown
    case .underwaterDiving:
        .waterWavesAndArrowTriangleheadDown
    case .other:
        .chevronRight2
    @unknown default:
        .chevronRight2
    }
  }
}

extension HKWorkoutActivityType: @retroactive CaseIterable {
  public static var allCases: [HKWorkoutActivityType] {
    [
      .americanFootball,
      .archery,
      .australianFootball,
      .badminton,
      .baseball,
      .basketball,
      .bowling,
      .boxing,
      .climbing,
      .cricket,
      .crossTraining,
      .curling,
      .cycling,
      .elliptical,
      .equestrianSports,
      .fencing,
      .fishing,
      .functionalStrengthTraining,
      .golf,
      .gymnastics,
      .handball,
      .hiking,
      .hockey,
      .hunting,
      .lacrosse,
      .martialArts,
      .mindAndBody,
      .paddleSports,
      .play,
      .preparationAndRecovery,
      .racquetball,
      .rowing,
      .rugby,
      .running,
      .sailing,
      .skatingSports,
      .snowSports,
      .soccer,
      .softball,
      .squash,
      .stairClimbing,
      .surfingSports,
      .swimming,
      .tableTennis,
      .tennis,
      .trackAndField,
      .traditionalStrengthTraining,
      .volleyball,
      .walking,
      .waterFitness,
      .waterPolo,
      .waterSports,
      .wrestling,
      .yoga,
      .barre,
      .coreTraining,
      .crossCountrySkiing,
      .downhillSkiing,
      .flexibility,
      .highIntensityIntervalTraining,
      .jumpRope,
      .kickboxing,
      .pilates,
      .snowboarding,
      .stairs,
      .stepTraining,
      .wheelchairWalkPace,
      .wheelchairRunPace,
      .taiChi,
      .mixedCardio,
      .handCycling,
      .discSports,
      .fitnessGaming,
      .cardioDance,
      .socialDance,
      .pickleball,
      .cooldown,
      .swimBikeRun,
      .transition,
      .underwaterDiving,
      .other
    ]
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
  static let locationAwareTypes: [HKWorkoutActivityType] = [
    .cycling, .walking, .running, .rowing, .soccer, .hockey, .skatingSports, .swimming
  ]
}
