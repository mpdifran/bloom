//
//  ReminderTriggerObserver.swift
//  Bloom
//
//  Created by Assistant on 2025-08-09.
//

import Foundation
import HealthKit
import CoreHealth
import DataContainer
import BloomFoundation

/// Observes HealthKit changes and automatically completes reminders based on configured triggers
@MainActor
final class ReminderTriggerObserver {
  static let shared = ReminderTriggerObserver()
  
  private let healthStore = HKHealthStore()
  private let remindersManager = RemindersManager.shared
  private let modelActor = ReminderModelActor.standard()
  
  private var observerHandles: [HKObserverQueryHandle] = []
  
  private init() {}
  
  // MARK: - Public Methods
  
  /// Starts observing HealthKit changes for reminder triggers
  func startObserving() {
    Task {
      await setupObservers()
      await registerBackgroundDelivery()
    }
  }
  
  /// Stops all health data observations
  func stopObserving() {
    // Clear the handles array - the queries will be stopped automatically in the handles' deinit
    observerHandles.removeAll()
  }
  
  // MARK: - Private Methods
  
  private func setupObservers() async {
    let startDate = Calendar.current.startOfDay(for: Date())
    
    // Observe body mass (weight)
    let weightHandle = healthStore.observeChanges(
      sampleType: HKQuantityType(.bodyMass),
      startDate: startDate
    ) { [weak self] in
      await self?.handleWeightChange()
    }
    observerHandles.append(weightHandle)
    
    // Observe dietary water
    let waterHandle = healthStore.observeChanges(
      sampleType: HKQuantityType(.dietaryWater),
      startDate: startDate
    ) { [weak self] in
      await self?.handleWaterChange()
    }
    observerHandles.append(waterHandle)
    
    // Observe blood pressure
    let bloodPressureHandle = healthStore.observeChanges(
      sampleTypes: [
        HKQuantityType(.bloodPressureSystolic),
        HKQuantityType(.bloodPressureDiastolic)
      ],
      startDate: startDate
    ) { [weak self] in
      await self?.handleBloodPressureChange()
    }
    observerHandles.append(bloodPressureHandle)
    
    // Observe workouts
    let workoutHandle = healthStore.observeChanges(
      sampleType: .workoutType(),
      startDate: startDate
    ) { [weak self] in
      await self?.handleWorkoutChange()
    }
    observerHandles.append(workoutHandle)
  }
  
  private func registerBackgroundDelivery() async {
    // Enable background delivery for trigger sample types
    healthStore.enableBackgroundDelivery(objectType: HKQuantityType(.bodyMass))
    healthStore.enableBackgroundDelivery(objectType: HKQuantityType(.dietaryWater))
    healthStore.enableBackgroundDelivery(objectType: HKQuantityType(.bloodPressureSystolic))
    healthStore.enableBackgroundDelivery(objectType: HKQuantityType(.bloodPressureDiastolic))
    healthStore.enableBackgroundDelivery(objectType: .workoutType())
  }
  
  // MARK: - Change Handlers
  
  private func handleWeightChange() async {
    await processTrigger(for: .logWeight)
  }
  
  private func handleWaterChange() async {
    await processTrigger(for: .logWater)
  }
  
  private func handleBloodPressureChange() async {
    await processTrigger(for: .logBloodPressure)
  }
  
  private func handleWorkoutChange() async {
    // Fetch the most recent workout to determine its type
    do {
      let workouts = try await healthStore.fetchWorkouts(
        dateRange: .duringDay(Date()),
        limit: 1
      )
      
      guard let workout = workouts.first else { return }
      
      // Determine which trigger type to process based on workout activity type
      let activityType = workout.workoutActivityType
      
      if Array.strengthTrainingTypes.contains(activityType) {
        await processTrigger(for: .logStrengthTraining)
      }
      
      if Array.cardioTypes.contains(activityType) {
        await processTrigger(for: .logCardio)
      }
      
      if Array.mobilityAndFlexibilityTypes.contains(activityType) {
        await processTrigger(for: .logMobilityFlexibility)
      }
      
      if Array.highIntensityIntervalTrainingTypes.contains(activityType) {
        await processTrigger(for: .logHIIT)
      }
    } catch {
      print("Failed to fetch workout for trigger processing: \(error)")
    }
  }
  
  // MARK: - Trigger Processing
  
  private func processTrigger(for triggerType: ReminderTriggerType) async {
    do {
      // Find reminders with this trigger type that haven't been completed today
      let reminders = try await modelActor.fetchRemindersWithTrigger(triggerType)
      
      // Filter to uncompleted reminders for today
      let today = Date()
      let calendar = Calendar.current
      let uncompletedReminders = reminders.filter { reminder in
        !reminder.completionRecords.contains { record in
          calendar.isDate(record.completedDate, inSameDayAs: today)
        }
      }
      
      guard !uncompletedReminders.isEmpty else { return }
      
      // If multiple reminders, select the one with occurrence closest to current time
      let reminderToComplete = selectClosestReminder(from: uncompletedReminders)
      
      guard let reminderToComplete else { return }
      
      // Find the closest occurrence for today
      let occurrenceID = findClosestOccurrence(for: reminderToComplete, on: today)?.id
      
      // Mark the reminder as completed with trigger source to prevent side effects
      try await remindersManager.markReminderCompleted(
        withID: reminderToComplete.id,
        occurrenceID: occurrenceID,
        source: .trigger
      )
      
      print("Auto-completed reminder '\(reminderToComplete.title)' via trigger: \(triggerType.displayName)")
      
    } catch {
      print("Failed to process trigger \(triggerType): \(error)")
    }
  }
  
  private func selectClosestReminder(from reminders: [ReminderDTO]) -> ReminderDTO? {
    let now = Date()
    let calendar = Calendar.current
    let currentTimeInterval = TimeInterval(calendar.component(.hour, from: now) * 3600 + calendar.component(.minute, from: now) * 60)
    
    return reminders.min { reminder1, reminder2 in
      let occurrence1 = findClosestOccurrence(for: reminder1, on: now)
      let occurrence2 = findClosestOccurrence(for: reminder2, on: now)
      
      let time1 = occurrence1?.timeOfDay ?? 0
      let time2 = occurrence2?.timeOfDay ?? 0
      
      let diff1 = abs(time1 - currentTimeInterval)
      let diff2 = abs(time2 - currentTimeInterval)
      
      return diff1 < diff2
    }
  }
  
  private func findClosestOccurrence(for reminder: ReminderDTO, on date: Date) -> ReminderOccurrenceDTO? {
    let calendar = Calendar.current
    let currentTimeInterval = TimeInterval(calendar.component(.hour, from: date) * 3600 + calendar.component(.minute, from: date) * 60)
    
    // Filter occurrences that apply to today
    let todayOccurrences = reminder.occurrences.filter { occurrence in
      switch occurrence.cadenceType {
      case .daily:
        return true
      case .weekly:
        let weekday = calendar.component(.weekday, from: date)
        return occurrence.daysOfWeek?.contains(weekday) ?? false
      case .monthly:
        let day = calendar.component(.day, from: date)
        return occurrence.dayOfMonth == day
      case .yearly:
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return occurrence.monthOfYear == month && occurrence.dayOfYear == day
      }
    }
    
    // Find the occurrence closest to current time
    return todayOccurrences.min { occ1, occ2 in
      let diff1 = abs(occ1.timeOfDay - currentTimeInterval)
      let diff2 = abs(occ2.timeOfDay - currentTimeInterval)
      return diff1 < diff2
    }
  }
}