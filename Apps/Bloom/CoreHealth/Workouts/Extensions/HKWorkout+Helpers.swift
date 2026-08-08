//
//  HKWorkout+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-14.
//

import Foundation
import HealthKit
import BloomFoundation

public extension HKWorkout {

  var totalTimeString: String {
      let formatter = DateComponentsFormatter()
      formatter.allowedUnits = [.hour, .minute, .second]
      formatter.zeroFormattingBehavior = .pad
      return formatter.string(from: duration) ?? ""
  }

  var activeEnergyBurned: HKQuantity {
    if let energy = statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity() {
      return energy
    }
    return HKQuantity(unit: .largeCalorie(), doubleValue: 0)
  }

  var totalEnergyBurned: HKQuantity {
    let defaultQuantity = HKQuantity(unit: .largeCalorie(), doubleValue: 0)
    guard let activeEnergy = statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity() else {
      return defaultQuantity
    }
    guard let basalEnergy = statistics(for: HKQuantityType(.basalEnergyBurned))?.sumQuantity() else {
      return activeEnergy
    }
    return basalEnergy.sum(activeEnergy, unit: .largeCalorie())
  }

  var averageHeartRate: HKQuantity {
    let defaultQuantity = HKQuantity(unit: .bpm(), doubleValue: 0)
    guard
      let statistics = statistics(for: HKQuantityType(.heartRate)),
      let average = statistics.averageQuantity()
    else {
      return defaultQuantity
    }
    return average
  }

  var totalDistanceWalkingRunning: HKQuantity? {
    statistics(for: HKQuantityType(.distanceWalkingRunning))?.sumQuantity()
  }

  var totalDistanceCycling: HKQuantity? {
    statistics(for: HKQuantityType(.distanceCycling))?.sumQuantity()
  }

  var totalDistanceWalkingRunningCycling: HKQuantity? {
    let totalDistance = (totalDistanceWalkingRunning?.doubleValue(for: .meter()) ?? 0) + (totalDistanceCycling?.doubleValue(for: .meter()) ?? 0)

    if totalDistance < 1 {
      return nil
    }
    return HKQuantity(unit: .meter(), doubleValue: totalDistance)
  }

  var elevationAscended: HKQuantity? {
    metadata?[HKMetadataKeyElevationAscended] as? HKQuantity
  }
  
  var elevationDescended: HKQuantity? {
    metadata?[HKMetadataKeyElevationDescended] as? HKQuantity
  }

  /// Determines the location type (indoor/outdoor) from workout metadata.
  /// - Parameter hasRoute: Whether the workout has an associated HKWorkoutRoute (indicates outdoor with GPS)
  /// - Returns: The inferred location type
  func inferredLocationType(hasRoute: Bool) -> HKWorkoutSessionLocationType {
    // Swimming has its own metadata key
    if workoutActivityType == .swimming {
      if let rawValue = metadata?[HKMetadataKeySwimmingLocationType] as? NSNumber,
         let swimmingLocation = HKWorkoutSwimmingLocationType(rawValue: rawValue.intValue) {
        return swimmingLocation == .pool ? .indoor : .outdoor
      }
      return .unknown
    }

    // Only classify indoor/outdoor for workout types that have meaningful variants
    guard [HKWorkoutActivityType].locationAwareTypes.contains(workoutActivityType) else {
      return .unknown
    }

    // Check indoor metadata flag
    if let isIndoor = metadata?[HKMetadataKeyIndoorWorkout] as? Bool {
      return isIndoor ? .indoor : .outdoor
    }

    // If has route data (GPS), assume outdoor
    if hasRoute {
      return .outdoor
    }

    return .unknown
  }

  // TODO: Why do we have this??
//  var duration: TimeInterval {
//    endDate.timeIntervalSince(startDate)
//  }

  /// Returns a display name including indoor/outdoor context when available.
  /// Uses activity-specific names (e.g. "Indoor Run", "Pool Swim") for known combinations,
  /// and a generic "Indoor/Outdoor" prefix for other types.
  func displayName(hasRoute: Bool = false) -> String {
    let locationType = inferredLocationType(hasRoute: hasRoute)

    switch (workoutActivityType, locationType) {
    case (.cycling, .indoor): return "Indoor Cycle"
    case (.cycling, .outdoor): return "Outdoor Cycle"
    case (.walking, .indoor): return "Indoor Walk"
    case (.walking, .outdoor): return "Outdoor Walk"
    case (.running, .indoor): return "Indoor Run"
    case (.running, .outdoor): return "Outdoor Run"
    case (.rowing, .indoor): return "Indoor Row"
    case (.rowing, .outdoor): return "Outdoor Row"
    case (.soccer, .indoor): return "Indoor Soccer"
    case (.soccer, .outdoor): return "Outdoor Soccer"
    case (.hockey, .indoor): return "Indoor Hockey"
    case (.hockey, .outdoor): return "Outdoor Hockey"
    case (.skatingSports, .indoor): return "Indoor Skating"
    case (.skatingSports, .outdoor): return "Outdoor Skating"
    case (.swimming, .indoor): return "Pool Swim"
    case (.swimming, .outdoor): return "Open Water Swim"
    default:
      switch locationType {
      case .indoor: return "Indoor \(workoutActivityType.name)"
      case .outdoor: return "Outdoor \(workoutActivityType.name)"
      default: return workoutActivityType.name
      }
    }
  }

  var dateRange: DateRange {
    DateRange(startDate, endDate)
  }

  /// The recording device/app name (e.g. "Apple Watch"), preferring the hardware device name
  /// and falling back to the data source name.
  var sourceName: String {
    device?.name ?? sourceRevision.source.name
  }
}
