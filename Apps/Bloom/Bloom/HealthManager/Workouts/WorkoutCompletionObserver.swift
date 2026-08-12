//
//  WorkoutCompletionObserver.swift
//  Bloom
//
//  Created by Claude on 2026-01-23.
//

import Foundation
import HealthKit
import CoreHealth
import BloomFoundation

public final actor WorkoutCompletionObserver {
  public static let shared = WorkoutCompletionObserver()

  private var workoutObserverQueryHandle: HKObserverQueryHandle?
  private var backgroundDeliveryHandle: HKBackgroundDeliveryHandle?

  private let healthStore = HKHealthStore()

  // Track notified workout UUIDs to avoid duplicate notifications
  private static let notifiedWorkoutsKey = "WorkoutCompletionObserver.notifiedWorkouts"

  private init() { }
}

// MARK: - Public API

public extension WorkoutCompletionObserver {

  func startObserving() async {
    // Guard against multiple registrations
    guard workoutObserverQueryHandle == nil else { return }

    // Enable background delivery for workouts
    backgroundDeliveryHandle = await HealthStoreFetcher.shared.enableBackgroundDelivery(
      objectType: HKObjectType.workoutType(),
      frequency: .immediate
    )

    // Start observing workout changes (look back 2 hours to catch recent completions)
    workoutObserverQueryHandle = healthStore.observeChanges(
      sampleType: HKObjectType.workoutType(),
      startDate: Calendar.current.date(byAdding: .hour, value: -2, to: .now) ?? .now
    ) { [weak self] in
      await self?.handleWorkoutChange()
    }
  }
}

// MARK: - Workout Change Handling

private extension WorkoutCompletionObserver {

  func handleWorkoutChange() async {
    // Fetch recent workouts (last 2 hours to catch just-completed ones)
    let workouts = await HealthStoreFetcher.shared.fetchWorkouts(dateRange: .trailingHoursFromNow(2))
    guard workouts.isNotEmpty else { return }

    // Process only new workouts that haven't been notified
    let notifiedUUIDs = loadNotifiedWorkoutUUIDs()
    let newWorkouts = workouts.filter { !notifiedUUIDs.contains($0.uuid.uuidString) }

    if newWorkouts.isNotEmpty {
      internalLog(.workoutAnalysis, "Detected \(newWorkouts.count) new workout(s)")
    }

    for workout in newWorkouts {
      await processWorkoutCompletion(workout)
    }
  }

  func processWorkoutCompletion(_ workout: HKWorkout) async {
    // Mark as notified immediately to prevent duplicates
    markWorkoutAsNotified(workout.uuid.uuidString)

    internalLog(.workoutAnalysis, "Processing \(workout.workoutActivityType.canonicalName) workout")

    // Check if workout notifications are enabled (must access on main thread)
    let isEnabled = await MainActor.run { NotificationPreferences.shared.workoutCompletionEnabled }
    guard isEnabled else { return }

    // Calculate bio age change using the optimized method
    let bioAgeDelta = await BiologicalAgeCalculator.shared.calculateWorkoutBioAgeDelta()

    // Send notification
    await sendWorkoutCompletionNotification(
      workout: workout,
      bioAgeDelta: bioAgeDelta
    )
  }

  func sendWorkoutCompletionNotification(
    workout: HKWorkout,
    bioAgeDelta: Double?
  ) async {
    let title = "\(workout.workoutActivityType.name) Workout Analysis Complete"
    let subtitle: String

    if let delta = bioAgeDelta {
      // Convert years to hours (1 year = 8,760 hours)
      let hoursChange = abs(delta * 8760)

      if delta < 0 {
        // Negative delta means they got younger (better)
        if hoursChange >= 24 {
          let days = Int(hoursChange / 24)
          subtitle = days == 1 ? "You're now 1 day younger!" : "You're now \(days) days younger!"
        } else {
          let hours = Int(hoursChange)
          subtitle = hours == 1 ? "You're now 1 hour younger!" : "You're now \(hours) hours younger!"
        }
      } else {
        subtitle = "Tap to see your workout analysis"
      }
    } else {
      // No significant change or couldn't calculate
      subtitle = "Tap to see your workout analysis"
    }

    await NotificationManager.shared.sendWorkoutNotification(
      title: title,
      subtitle: subtitle,
      workoutUUID: workout.uuid.uuidString
    )

    internalLog(.workoutAnalysis, "Sent notification: \(subtitle)")
  }
}

// MARK: - UserDefaults Persistence

private extension WorkoutCompletionObserver {

  func loadNotifiedWorkoutUUIDs() -> Set<String> {
    guard let data = UserDefaults.standard.data(forKey: Self.notifiedWorkoutsKey),
          let dict = try? JSONDecoder().decode([String: Date].self, from: data) else {
      return []
    }

    // Clean up entries older than 7 days
    let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
    let recentEntries = dict.filter { $0.value > cutoff }

    // Save cleaned entries back if we removed any
    if recentEntries.count != dict.count {
      saveNotifiedWorkouts(recentEntries)
    }

    return Set(recentEntries.keys)
  }

  func markWorkoutAsNotified(_ uuid: String) {
    var dict = loadNotifiedWorkoutsDict()
    dict[uuid] = Date.now
    saveNotifiedWorkouts(dict)
  }

  func loadNotifiedWorkoutsDict() -> [String: Date] {
    guard let data = UserDefaults.standard.data(forKey: Self.notifiedWorkoutsKey),
          let dict = try? JSONDecoder().decode([String: Date].self, from: data) else {
      return [:]
    }
    return dict
  }

  func saveNotifiedWorkouts(_ dict: [String: Date]) {
    guard let data = try? JSONEncoder().encode(dict) else { return }
    UserDefaults.standard.set(data, forKey: Self.notifiedWorkoutsKey)
  }
}
