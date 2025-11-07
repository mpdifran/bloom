//
//  GoalWidgetHealthObserver.swift
//  Bloom
//
//  Created by Claude Code on 2025-11-07.
//

import Foundation
import HealthKit
import CoreHealth
import DataContainer
import SwiftData
import BloomFoundation

public final actor GoalWidgetHealthObserver {
  public static let shared = GoalWidgetHealthObserver()

  private var observerHandles: [HKSampleType: HKObserverQueryHandle] = [:]
  private var backgroundDeliveryHandles: [HKObjectType: HKBackgroundDeliveryHandle] = [:]

  private let healthStore = HKHealthStore()
  private var monitoredSampleTypes: Set<HKSampleType> = []

  private init() { }

  /// Start observing health data for all active goals
  public func startObserving(modelContext: ModelContext) async {
    // Fetch all active goals
    let habits: [Habit]
    do {
      let descriptor = FetchDescriptor<Habit>(
        predicate: #Predicate<Habit> { habit in
          habit.endDate == nil
        }
      )
      habits = try modelContext.fetch(descriptor)
    } catch {
      print("Failed to fetch habits for GoalWidgetHealthObserver: \(error)")
      return
    }

    // Collect all unique sample types from active goals
    let sampleTypes = Set(habits.flatMap { $0.targetMetric.sampleTypes })

    // Update monitored types
    await updateMonitoredTypes(sampleTypes)
  }

  /// Update which health types are being monitored
  /// Call this when goals are created, updated, or deleted
  public func updateMonitoredTypes(_ newSampleTypes: Set<HKSampleType>) async {
    // Determine which types to start monitoring
    let typesToAdd = newSampleTypes.subtracting(monitoredSampleTypes)

    // Determine which types to stop monitoring
    let typesToRemove = monitoredSampleTypes.subtracting(newSampleTypes)

    // Stop observing removed types
    for sampleType in typesToRemove {
      observerHandles.removeValue(forKey: sampleType)
      if let objectType = sampleType as? HKObjectType {
        backgroundDeliveryHandles.removeValue(forKey: objectType)
      }
    }

    // Start observing new types
    for sampleType in typesToAdd {
      await startObserving(sampleType: sampleType)
    }

    // Update tracked types
    monitoredSampleTypes = newSampleTypes
  }

  /// Start observing a specific sample type
  private func startObserving(sampleType: HKSampleType) async {
    // Enable background delivery with hourly frequency (battery-friendly)
    if let objectType = sampleType as? HKObjectType {
      let backgroundHandle = await HealthStoreFetcher.shared.enableBackgroundDelivery(
        objectType: objectType,
        frequency: .hourly
      )
      backgroundDeliveryHandles[objectType] = backgroundHandle
    }

    // Set up observer query
    let observerHandle = healthStore.observeChanges(
      sampleType: sampleType,
      startDate: Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .now
    ) { [weak self] in
      await self?.handleHealthDataChange()
    }

    observerHandles[sampleType] = observerHandle
  }

  /// Handle health data changes by updating widget cache
  private func handleHealthDataChange() async {
    // Update the widget cache with latest health data
    let modelContext = ModelContext(ContainerHolder.shared.container)
    await GoalWidgetCacheManager.shared.updateCache(modelContext: modelContext)

    // Refresh all goal widgets
    GoalWidgetCache.refreshWidgets()
  }
}
