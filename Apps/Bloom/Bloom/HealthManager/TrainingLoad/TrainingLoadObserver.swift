//
//  TrainingLoadObserver.swift
//  Bloom
//
//  Created by Assistant on 2025-01-25.
//

import Foundation
import HealthKit
import CoreHealth

public final actor TrainingLoadObserver {
  public static let shared = TrainingLoadObserver()

  private var workoutObserverQueryHandle: HKObserverQueryHandle?
  private var userEffortScoreObserverQueryHandle: HKObserverQueryHandle?
  private var estimatedEffortScoreObserverQueryHandle: HKObserverQueryHandle?
  
  private var backgroundDeliveryHandles: [HKBackgroundDeliveryHandle] = []

  private let healthStore = HKHealthStore()

  private init() { }
}

public extension TrainingLoadObserver {

  func observeTrainingLoad() async {
    // Enable background delivery for immediate updates
    backgroundDeliveryHandles = await [
      HealthStoreFetcher.shared.enableBackgroundDelivery(
        objectType: HKObjectType.workoutType(),
        frequency: .immediate
      ),
      HealthStoreFetcher.shared.enableBackgroundDelivery(
        objectType: HKQuantityType(.workoutEffortScore),
        frequency: .immediate
      ),
      HealthStoreFetcher.shared.enableBackgroundDelivery(
        objectType: HKQuantityType(.estimatedWorkoutEffortScore),
        frequency: .immediate
      )
    ].compactMap { $0 }

    // Observe workout changes
    workoutObserverQueryHandle = healthStore.observeChanges(
      sampleType: HKObjectType.workoutType(),
      startDate: Calendar.current.date(byAdding: .day, value: -56, to: .now) ?? .now
    ) { [weak self] in
      await self?.handleTrainingLoadDataChange()
    }

    // Observe user effort score changes
    userEffortScoreObserverQueryHandle = healthStore.observeChanges(
      sampleType: HKQuantityType(.workoutEffortScore),
      startDate: Calendar.current.date(byAdding: .day, value: -56, to: .now) ?? .now
    ) { [weak self] in
      await self?.handleTrainingLoadDataChange()
    }

    // Observe estimated effort score changes
    estimatedEffortScoreObserverQueryHandle = healthStore.observeChanges(
      sampleType: HKQuantityType(.estimatedWorkoutEffortScore),
      startDate: Calendar.current.date(byAdding: .day, value: -56, to: .now) ?? .now
    ) { [weak self] in
      await self?.handleTrainingLoadDataChange()
    }
  }
}

private extension TrainingLoadObserver {

  func handleTrainingLoadDataChange() async {
    // Invalidate cached data and trigger recalculation
    await TrainingLoadCalculator.shared.invalidateAndRecalculate()
  }
}