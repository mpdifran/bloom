//
//  WorkoutHeartRateReport.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-20.
//

import Foundation
@preconcurrency import HealthKit
import AppFoundations
import SwiftUI

public struct WorkoutHeartRateReport: Identifiable, Hashable, Sendable {
  public var id: Int { hashValue }

  public let workout: HKWorkout
  public let heartRateSamples: [HKQuantitySample]
  public let heartRateZones: HeartRateZones
  public let heartZoneDistribution: WorkoutHeartZoneDistribution

  public init(
    workout: HKWorkout,
    heartRateSamples: [HKQuantitySample],
    heartRateZones: HeartRateZones
  ) {
    self.workout = workout
    self.heartRateSamples = heartRateSamples
    self.heartRateZones = heartRateZones

    var zoneDurations: [TimeInterval] = [0, 0, 0, 0, 0, 0]

    var currentZone = 0
    var zoneStartDate: Date? = heartRateSamples.first?.startDate
    var zoneEndDate: Date?

    for heartRateSample in heartRateSamples {
      var sampleZone: Int
      let bpm = heartRateSample.quantity.doubleValue(for: .bpm())
      if bpm < heartRateZones.zone1 {
        sampleZone = 0
      } else if bpm < heartRateZones.zone2 {
        sampleZone = 1
      } else if bpm < heartRateZones.zone3 {
        sampleZone = 2
      } else if bpm < heartRateZones.zone4 {
        sampleZone = 3
      } else if bpm < heartRateZones.zone5 {
        sampleZone = 4
      } else {
        sampleZone = 5
      }

      if sampleZone != currentZone {
        if let startDate = zoneStartDate {
          let duration = heartRateSample.startDate.timeIntervalSince(startDate)

          zoneDurations[currentZone] += duration
        }
        currentZone = sampleZone
        zoneStartDate = heartRateSample.startDate
      }

      zoneEndDate = heartRateSample.startDate
    }

    // Add last entry
    if let zoneStartDate, let zoneEndDate {
      let duration = zoneEndDate.timeIntervalSince(zoneStartDate)
      zoneDurations[currentZone] += duration
    }

    self.heartZoneDistribution = WorkoutHeartZoneDistribution(
      totalDuration: HKQuantity(unit: .second(), doubleValue: workout.duration),
      zone1: HKQuantity(unit: .second(), doubleValue: max(zoneDurations[1], 0)),
      zone2: HKQuantity(unit: .second(), doubleValue: max(zoneDurations[2], 0)),
      zone3: HKQuantity(unit: .second(), doubleValue: max(zoneDurations[3], 0)),
      zone4: HKQuantity(unit: .second(), doubleValue: max(zoneDurations[4], 0)),
      zone5: HKQuantity(unit: .second(), doubleValue: max(zoneDurations[5], 0))
    )
  }
}

public extension WorkoutHeartRateReport {

  func zone(for sample: HKQuantitySample) -> Int {
    let bpm = sample.quantity.doubleValue(for: .bpm())
    if bpm < heartRateZones.zone1 {
      return 0
    } else if bpm < heartRateZones.zone2 {
      return 1
    } else if bpm < heartRateZones.zone3 {
      return 2
    } else if bpm < heartRateZones.zone4 {
      return 3
    } else if bpm < heartRateZones.zone5 {
      return 4
    } else {
      return 5
    }
  }

  func zoneColor(for sample: HKQuantitySample) -> Color {
    zoneColor(for: zone(for: sample))
  }

  func zoneColor(for zone: Int) -> Color {
    switch zone {
    case 1: return .heartRateZone1
    case 2: return .heartRateZone2
    case 3: return .heartRateZone3
    case 4: return .heartRateZone4
    case 5: return .heartRateZone5
    default: return .gray
    }
  }
}

public extension WorkoutHeartRateReport {

  var normalizedDate: Date {
    Calendar.current.startOfDay(for: workout.endDate)
  }

  var minHeartRate: Double? {
    heartRateSamples.map({ $0.quantity.doubleValue(for: .bpm()) }).min()
  }

  var maxHeartRate: Double? {
    heartRateSamples.map({ $0.quantity.doubleValue(for: .bpm()) }).max()
  }

  var averageHeartRate: Double? {
    heartRateSamples.reduce(into: 0) { result, sample in
      result += sample.quantity.doubleValue(for: .bpm())
    } / Double(heartRateSamples.count)
  }
}

public extension WorkoutHeartRateReport {
  struct WorkoutHeartZoneDistribution: Hashable, Sendable {
    public let totalDuration: HKQuantity
    public let zone1: HKQuantity
    public let zone2: HKQuantity
    public let zone3: HKQuantity
    public let zone4: HKQuantity
    public let zone5: HKQuantity

    public init(
      totalDuration: HKQuantity,
      zone1: HKQuantity,
      zone2: HKQuantity,
      zone3: HKQuantity,
      zone4: HKQuantity,
      zone5: HKQuantity
    ) {
      self.totalDuration = totalDuration
      self.zone1 = zone1
      self.zone2 = zone2
      self.zone3 = zone3
      self.zone4 = zone4
      self.zone5 = zone5
    }

    public init() {
      self.totalDuration = HKQuantity(unit: .minute(), doubleValue: 0)
      self.zone1 = HKQuantity(unit: .minute(), doubleValue: 0)
      self.zone2 = HKQuantity(unit: .minute(), doubleValue: 0)
      self.zone3 = HKQuantity(unit: .minute(), doubleValue: 0)
      self.zone4 = HKQuantity(unit: .minute(), doubleValue: 0)
      self.zone5 = HKQuantity(unit: .minute(), doubleValue: 0)
    }
  }
}

public extension WorkoutHeartRateReport.WorkoutHeartZoneDistribution {

  var zone1Percent: Double {
    zone1.doubleValue(for: .minute()) / totalDuration.doubleValue(for: .minute())
  }

  var zone2Percent: Double {
    zone2.doubleValue(for: .minute()) / totalDuration.doubleValue(for: .minute())
  }

  var zone3Percent: Double {
    zone3.doubleValue(for: .minute()) / totalDuration.doubleValue(for: .minute())
  }

  var zone4Percent: Double {
    zone4.doubleValue(for: .minute()) / totalDuration.doubleValue(for: .minute())
  }

  var zone5Percent: Double {
    zone5.doubleValue(for: .minute()) / totalDuration.doubleValue(for: .minute())
  }

  var zone12Duration: HKQuantity {
    zone1.sum(zone2, unit: .minute())
  }

  var zone34Duration: HKQuantity {
    zone3.sum(zone4, unit: .minute())
  }

  var dominantZones: Set<Int> {
    [
      (zone1Percent, 1),
      (zone2Percent, 2),
      (zone3Percent, 3),
      (zone4Percent, 4),
      (zone5Percent, 5),
    ]
      .sorted(by: { $0.0 < $1.0 })
      .suffix(2)
      .map({ $0.1 })
      .asSet()
  }

  var maxPercent: Double {
    let values = [
      zone1Percent,
      zone2Percent,
      zone3Percent,
      zone4Percent,
      zone5Percent
    ]
    return values.max() ?? 1
  }

  var scaledDurationSum: HKQuantity {
    let total = zone1.doubleValue(for: .minute()) +
    zone2.doubleValue(for: .minute()) +
    zone3.doubleValue(for: .minute()) * .zone34Multiplier +
    zone4.doubleValue(for: .minute()) * .zone34Multiplier +
    zone5.doubleValue(for: .minute()) * .zone5Multiplier

    return HKQuantity(unit: .minute(), doubleValue: total)
  }
}

public extension WorkoutHeartRateReport.WorkoutHeartZoneDistribution {

  func sum(with other: WorkoutHeartRateReport.WorkoutHeartZoneDistribution) -> WorkoutHeartRateReport.WorkoutHeartZoneDistribution {
    WorkoutHeartRateReport.WorkoutHeartZoneDistribution(
      totalDuration: totalDuration.sum(other.totalDuration, unit: .minute()),
      zone1: zone1.sum(other.zone1, unit: .minute()),
      zone2: zone2.sum(other.zone2, unit: .minute()),
      zone3: zone3.sum(other.zone3, unit: .minute()),
      zone4: zone4.sum(other.zone4, unit: .minute()),
      zone5: zone5.sum(other.zone5, unit: .minute())
    )
  }
}

public extension Collection where Element == WorkoutHeartRateReport {

  func generateOverallDistribution() -> WorkoutHeartRateReport.WorkoutHeartZoneDistribution {
    reduce(WorkoutHeartRateReport.WorkoutHeartZoneDistribution()) { (partialResult, report) in
      partialResult.sum(with: report.heartZoneDistribution)
    }
  }

  func generateWorkoutTypeHeartRateReports() -> [WorkoutTypeHeartRateReport] {
    var workoutTypeReports = [WorkoutTypeHeartRateReport]()
    for workoutReport in self {
      if let existingReportIndex = workoutTypeReports.firstIndex(where: {
        $0.activityType == workoutReport.workout.workoutActivityType
      }) {
        let report = workoutTypeReports.remove(at: existingReportIndex)
        let newReport = report.appending(workoutReport: workoutReport)
        workoutTypeReports.insert(newReport, at: existingReportIndex)
      } else {
        let report = WorkoutTypeHeartRateReport(
          activityType: workoutReport.workout.workoutActivityType,
          workoutCount: 1,
          heartZoneDistribution: workoutReport.heartZoneDistribution
        )
        workoutTypeReports.append(report)
      }
    }
    return workoutTypeReports
  }
}
