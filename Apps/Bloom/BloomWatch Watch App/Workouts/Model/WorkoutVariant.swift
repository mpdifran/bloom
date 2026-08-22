//
//  WorkoutVariant.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-26.
//

import HealthKit
import SFSafeSymbols
import CoreHealth

struct WorkoutVariant: Hashable, Identifiable {
  let activityType: HKWorkoutActivityType
  let locationType: HKWorkoutSessionLocationType
  let symbol: SFSymbol
  let name: String

  var id: String { "\(activityType.rawValue)-\(locationType.rawValue)" }
}

// MARK: - Indoor/Outdoor Variants

extension WorkoutVariant {

  // MARK: Cycling
  static let outdoorCycling = WorkoutVariant(
    activityType: .cycling,
    locationType: .outdoor,
    symbol: .figureOutdoorCycle,
    name: String(localized: "Outdoor Cycle", comment: "Workout name")
  )
  static let indoorCycling = WorkoutVariant(
    activityType: .cycling,
    locationType: .indoor,
    symbol: .figureIndoorCycle,
    name: String(localized: "Indoor Cycle", comment: "Workout name")
  )

  // MARK: Walking
  static let outdoorWalking = WorkoutVariant(
    activityType: .walking,
    locationType: .outdoor,
    symbol: .figureWalk,
    name: String(localized: "Outdoor Walk", comment: "Workout name")
  )
  static let indoorWalking = WorkoutVariant(
    activityType: .walking,
    locationType: .indoor,
    symbol: .figureWalkTreadmill,
    name: String(localized: "Indoor Walk", comment: "Workout name")
  )

  // MARK: Running
  static let outdoorRunning = WorkoutVariant(
    activityType: .running,
    locationType: .outdoor,
    symbol: .figureRun,
    name: String(localized: "Outdoor Run", comment: "Workout name")
  )
  static let indoorRunning = WorkoutVariant(
    activityType: .running,
    locationType: .indoor,
    symbol: .figureRunTreadmill,
    name: String(localized: "Indoor Run", comment: "Workout name")
  )

  // MARK: Rowing
  static let outdoorRowing = WorkoutVariant(
    activityType: .rowing,
    locationType: .outdoor,
    symbol: .figureOutdoorRowing,
    name: String(localized: "Outdoor Row", comment: "Workout name")
  )
  static let indoorRowing = WorkoutVariant(
    activityType: .rowing,
    locationType: .indoor,
    symbol: .figureIndoorRowing,
    name: String(localized: "Indoor Row", comment: "Workout name")
  )

  // MARK: Soccer
  static let outdoorSoccer = WorkoutVariant(
    activityType: .soccer,
    locationType: .outdoor,
    symbol: .figureOutdoorSoccer,
    name: String(localized: "Outdoor Soccer", comment: "Workout name")
  )
  static let indoorSoccer = WorkoutVariant(
    activityType: .soccer,
    locationType: .indoor,
    symbol: .figureIndoorSoccer,
    name: String(localized: "Indoor Soccer", comment: "Workout name")
  )

  // MARK: Hockey
  static let outdoorHockey = WorkoutVariant(
    activityType: .hockey,
    locationType: .outdoor,
    symbol: .figureIceHockey,
    name: String(localized: "Outdoor Hockey", comment: "Workout name")
  )
  static let indoorHockey = WorkoutVariant(
    activityType: .hockey,
    locationType: .indoor,
    symbol: .figureIceHockey,
    name: String(localized: "Indoor Hockey", comment: "Workout name")
  )

  // MARK: Skating
  static let outdoorSkating = WorkoutVariant(
    activityType: .skatingSports,
    locationType: .outdoor,
    symbol: .figureIceSkating,
    name: String(localized: "Outdoor Skating", comment: "Workout name")
  )
  static let indoorSkating = WorkoutVariant(
    activityType: .skatingSports,
    locationType: .indoor,
    symbol: .figureIceSkating,
    name: String(localized: "Indoor Skating", comment: "Workout name")
  )

  // MARK: Swimming
  static let openWaterSwimming = WorkoutVariant(
    activityType: .swimming,
    locationType: .outdoor,
    symbol: .figureOpenWaterSwim,
    name: String(localized: "Open Water Swim", comment: "Workout name")
  )
  static let poolSwimming = WorkoutVariant(
    activityType: .swimming,
    locationType: .indoor,
    symbol: .figurePoolSwim,
    name: String(localized: "Pool Swim", comment: "Workout name")
  )
}

// MARK: - Factory for Non-Variant Workouts

extension WorkoutVariant {

  /// Creates a variant for workouts that don't have indoor/outdoor options
  static func simple(_ activityType: HKWorkoutActivityType) -> WorkoutVariant {
    WorkoutVariant(
      activityType: activityType,
      locationType: .unknown,
      symbol: activityType.systemSymbol,
      name: activityType.name
    )
  }

  /// All possible workout variants from all categories
  static var allVariants: [WorkoutVariant] {
    WorkoutCategory.allCases.flatMap { $0.workoutVariants }
  }

  /// Resolve a variant ID back to a WorkoutVariant
  static func from(id: String) -> WorkoutVariant? {
    allVariants.first { $0.id == id }
  }

  /// Creates a variant from a completed HKWorkout using its metadata to determine location type.
  /// - Parameters:
  ///   - workout: The completed workout from HealthKit
  ///   - hasRoute: Whether the workout has an associated HKWorkoutRoute (GPS data)
  static func from(workout: HKWorkout, hasRoute: Bool) -> WorkoutVariant {
    let locationType = workout.inferredLocationType(hasRoute: hasRoute)
    let activityType = workout.workoutActivityType

    // Return predefined variants for known indoor/outdoor combinations
    switch (activityType, locationType) {
    case (.cycling, .indoor): return .indoorCycling
    case (.cycling, .outdoor): return .outdoorCycling
    case (.walking, .indoor): return .indoorWalking
    case (.walking, .outdoor): return .outdoorWalking
    case (.running, .indoor): return .indoorRunning
    case (.running, .outdoor): return .outdoorRunning
    case (.rowing, .indoor): return .indoorRowing
    case (.rowing, .outdoor): return .outdoorRowing
    case (.soccer, .indoor): return .indoorSoccer
    case (.soccer, .outdoor): return .outdoorSoccer
    case (.hockey, .indoor): return .indoorHockey
    case (.hockey, .outdoor): return .outdoorHockey
    case (.skatingSports, .indoor): return .indoorSkating
    case (.skatingSports, .outdoor): return .outdoorSkating
    case (.swimming, .indoor): return .poolSwimming
    case (.swimming, .outdoor): return .openWaterSwimming
    default:
      return WorkoutVariant(
        activityType: activityType,
        locationType: locationType,
        symbol: activityType.systemSymbol,
        name: workout.displayName(hasRoute: hasRoute)
      )
    }
  }
}

