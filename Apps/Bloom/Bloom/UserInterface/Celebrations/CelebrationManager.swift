//
//  CelebrationManager.swift
//  Bloom
//
//  Created by Claude on 2026-02-26.
//

import Foundation
import DataContainer
import CoreHealth
import BloomFoundation
@preconcurrency import HealthKit

/// Checks for celebration-worthy milestones on app foreground.
/// Called from `RootViewModalPresentationManager.determineSheetToPresent()`.
@MainActor
@Observable
final class CelebrationManager {

  static let shared = CelebrationManager()

  private let defaults = UserDefaults.standard

  #if DEBUG
  var debugOverrideCelebration: CelebrationKind?
  #endif

  private init() { }
}

// MARK: - Public API

extension CelebrationManager {

  /// Checks for a celebration to present, returning the highest-priority uncelebrated milestone.
  /// Priority: bio age > goal streak > zone minutes > sleep.
  func checkForCelebration() async -> CelebrationKind? {
    #if DEBUG
    if let override = debugOverrideCelebration {
      debugOverrideCelebration = nil
      return override
    }
    #endif

    guard CelebrationPreferences.shared.celebrationsEnabled else { return nil }

    if let bioAgeCelebration = await checkBiologicalAge() {
      return bioAgeCelebration
    }

    if let streakCelebration = await checkGoalStreaks() {
      return streakCelebration
    }

    if let zoneMinutesCelebration = await checkZoneMinutes() {
      return zoneMinutesCelebration
    }

    if let sleepCelebration = await checkPerfectSleep() {
      return sleepCelebration
    }

    return nil
  }
}

// MARK: - Bio Age Check

private extension CelebrationManager {

  func checkBiologicalAge() async -> CelebrationKind? {
    let modelActor = BiologicalAgeRecordModelActor.standard()
    guard let latest = try? await modelActor.fetchLatest() else { return nil }

    let yearsYounger = Int(-latest.ageDelta)
    guard yearsYounger > 0 else { return nil }

    let milestones = [10, 5, 3, 2, 1]
    let lastCelebrated = defaults.integer(forKey: Keys.bioAgeLastCelebratedThreshold)

    for milestone in milestones {
      if yearsYounger >= milestone && lastCelebrated < milestone {
        defaults.set(milestone, forKey: Keys.bioAgeLastCelebratedThreshold)
        return .biologicalAge(yearsYounger: milestone)
      }
    }

    return nil
  }
}

// MARK: - Goal Streak Check

private extension CelebrationManager {

  func checkGoalStreaks() async -> CelebrationKind? {
    let streaks = await GoalStreakCalculator.shared.calculateAllStreaks()
    let milestones = [365, 180, 90, 60, 30, 14, 7, 3]

    // Find the highest uncelebrated streak milestone across all habits
    for (habit, streak) in streaks.sorted(by: { $0.streak > $1.streak }) {
      for milestone in milestones {
        if streak >= milestone {
          let key = Keys.goalStreak(metric: habit.targetMetric.rawValue, milestone: milestone)
          if !defaults.bool(forKey: key) {
            defaults.set(true, forKey: key)
            return .goalStreak(metricName: habit.targetMetric.name, days: milestone)
          }
          // If this milestone was already celebrated, don't check lower milestones for this habit
          break
        }
      }
    }

    return nil
  }
}

// MARK: - Zone Minutes Check

private extension CelebrationManager {

  func checkZoneMinutes() async -> CelebrationKind? {
    guard let heartRateZones = await HealthStoreFetcher.shared.heartRateZones() else { return nil }

    let dateRange = DateRange.trailingDaysFromEndOfYesterday(6)
    let details = await HealthStoreFetcher.shared.fetchExerciseEffectivenessDetails(
      heartRateZones: heartRateZones,
      dateRange: dateRange
    )

    let totalZoneMinutes = details.overallHeartZoneDistribution.scaledDurationSum.doubleValue(for: .minute())

    // Check 300 first (higher milestone)
    if totalZoneMinutes >= 300 {
      let key = Keys.zoneMinutes300
      if !defaults.bool(forKey: key) {
        defaults.set(true, forKey: key)
        return .zoneMinutes(minutes: 300)
      }
    }

    if totalZoneMinutes >= 150 {
      let key = Keys.zoneMinutes150
      if !defaults.bool(forKey: key) {
        defaults.set(true, forKey: key)
        return .zoneMinutes(minutes: 150)
      }
    }

    return nil
  }
}

// MARK: - Sleep Check

private extension CelebrationManager {

  func checkPerfectSleep() async -> CelebrationKind? {
    guard !defaults.bool(forKey: Keys.perfectSleep) else { return nil }

    let sleepAnalyses = await HealthStoreFetcher.shared.fetchSleepAnalysis(
      dateRange: .trailingDaysFromNow(6)
    )

    guard let latestSleep = sleepAnalyses.last else { return nil }

    if latestSleep.overallScore == 100 {
      defaults.set(true, forKey: Keys.perfectSleep)
      return .perfectSleep(latestSleep)
    }

    return nil
  }
}

// MARK: - UserDefaults Keys

private extension CelebrationManager {

  enum Keys {
    static let bioAgeLastCelebratedThreshold = "celebrations.bioAge.lastCelebratedThreshold"
    static let zoneMinutes150 = "celebrations.zoneMinutes.150"
    static let zoneMinutes300 = "celebrations.zoneMinutes.300"
    static let perfectSleep = "celebrations.perfectSleep"

    static func goalStreak(metric: String, milestone: Int) -> String {
      "celebrations.goalStreak.\(metric).\(milestone)"
    }
  }
}
