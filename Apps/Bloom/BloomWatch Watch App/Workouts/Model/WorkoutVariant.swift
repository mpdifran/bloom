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
    name: "Outdoor Cycle"
  )
  static let indoorCycling = WorkoutVariant(
    activityType: .cycling,
    locationType: .indoor,
    symbol: .figureIndoorCycle,
    name: "Indoor Cycle"
  )

  // MARK: Walking
  static let outdoorWalking = WorkoutVariant(
    activityType: .walking,
    locationType: .outdoor,
    symbol: .figureWalk,
    name: "Outdoor Walk"
  )
  static let indoorWalking = WorkoutVariant(
    activityType: .walking,
    locationType: .indoor,
    symbol: .figureWalkTreadmill,
    name: "Indoor Walk"
  )

  // MARK: Running
  static let outdoorRunning = WorkoutVariant(
    activityType: .running,
    locationType: .outdoor,
    symbol: .figureRun,
    name: "Outdoor Run"
  )
  static let indoorRunning = WorkoutVariant(
    activityType: .running,
    locationType: .indoor,
    symbol: .figureRunTreadmill,
    name: "Indoor Run"
  )

  // MARK: Rowing
  static let outdoorRowing = WorkoutVariant(
    activityType: .rowing,
    locationType: .outdoor,
    symbol: .figureOutdoorRowing,
    name: "Outdoor Row"
  )
  static let indoorRowing = WorkoutVariant(
    activityType: .rowing,
    locationType: .indoor,
    symbol: .figureIndoorRowing,
    name: "Indoor Row"
  )

  // MARK: Soccer
  static let outdoorSoccer = WorkoutVariant(
    activityType: .soccer,
    locationType: .outdoor,
    symbol: .figureOutdoorSoccer,
    name: "Outdoor Soccer"
  )
  static let indoorSoccer = WorkoutVariant(
    activityType: .soccer,
    locationType: .indoor,
    symbol: .figureIndoorSoccer,
    name: "Indoor Soccer"
  )

  // MARK: Hockey
  static let outdoorHockey = WorkoutVariant(
    activityType: .hockey,
    locationType: .outdoor,
    symbol: .figureIceHockey,
    name: "Outdoor Hockey"
  )
  static let indoorHockey = WorkoutVariant(
    activityType: .hockey,
    locationType: .indoor,
    symbol: .figureIceHockey,
    name: "Indoor Hockey"
  )

  // MARK: Skating
  static let outdoorSkating = WorkoutVariant(
    activityType: .skatingSports,
    locationType: .outdoor,
    symbol: .figureIceSkating,
    name: "Outdoor Skating"
  )
  static let indoorSkating = WorkoutVariant(
    activityType: .skatingSports,
    locationType: .indoor,
    symbol: .figureIceSkating,
    name: "Indoor Skating"
  )

  // MARK: Swimming
  static let openWaterSwimming = WorkoutVariant(
    activityType: .swimming,
    locationType: .outdoor,
    symbol: .figureOpenWaterSwim,
    name: "Open Water Swim"
  )
  static let poolSwimming = WorkoutVariant(
    activityType: .swimming,
    locationType: .indoor,
    symbol: .figurePoolSwim,
    name: "Pool Swim"
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
    default: return .simple(activityType)
    }
  }
}

