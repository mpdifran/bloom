//
//  WorkoutManager+watchOS.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-05.
//

import Foundation
import HealthKit
import BloomFoundation

#if os(watchOS)
public extension WorkoutManager {

  /// Phase 1: Prepare the workout session without starting data collection.
  /// Call this first, then show countdown, then call `beginWorkout()`.
  func prepareWorkout(workoutConfiguration: HKWorkoutConfiguration, shouldMirror: Bool) async throws {
    // Load heart rate zones from application context (synced from iOS)
    if let data = WatchChannel.shared.getApplicationContextData(for: WatchChannel.heartRateZonesKey),
       let zones = try? JSONDecoder.watch.decode(HeartRateZones.self, from: data) {
      heartRateZones = zones
    }

    session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
    builder = session?.associatedWorkoutBuilder()
    session?.delegate = self
    builder?.delegate = self
    builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: workoutConfiguration)

    try await session?.prepare()

    // Start mirroring the session to the companion device.
    if shouldMirror {
      try await session?.startMirroringToCompanionDevice()
      isMirroring = true
    }
  }

  /// Phase 2: Begin the workout session and start data collection.
  /// Call this after the countdown completes.
  func beginWorkout() async throws {
    let startDate = Date()
    session?.startActivity(with: startDate)
    try await builder?.beginCollection(at: startDate)
    print("Started session")
  }

  /// Convenience method that prepares and immediately begins a workout (skipping countdown).
  /// Used for workout switching and recovery scenarios.
  func startWorkout(workoutConfiguration: HKWorkoutConfiguration, shouldMirror: Bool) async throws {
    try await prepareWorkout(workoutConfiguration: workoutConfiguration, shouldMirror: shouldMirror)
    try await beginWorkout()
  }
  
  func handleReceivedData(_ data: Data) throws {
    guard let decodedQuantity = try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQuantity.self, from: data) else {
      return
    }
    water += decodedQuantity.doubleValue(for: HKUnit.fluidOunceUS())
    
    let sampleDate = Date()
    Task {
      let waterSample = [HKQuantitySample(type: HKQuantityType(.dietaryWater), quantity: decodedQuantity, start: sampleDate, end: sampleDate)]
      try await builder?.addSamples(waterSample)
    }
  }

  /// Ends the current workout, saves it, and immediately starts a new one
  /// - Parameter newConfiguration: Configuration for the new workout
  /// - Returns: The saved HKWorkout from the ended session (nil if discarded due to short duration)
  func switchWorkout(to newConfiguration: HKWorkoutConfiguration) async throws -> HKWorkout? {
    guard let session, let builder else {
      throw WorkoutError.noActiveSession
    }

    // Set flag to prevent ActiveWorkoutView from dismissing
    isSwitchingWorkout = true
    defer { isSwitchingWorkout = false }

    let endDate = Date()
    let elapsedTime = builder.elapsedTime(at: endDate)

    // 1. End current collection
    try await builder.endCollection(at: endDate)

    // 2. Save or discard based on duration
    let savedWorkout: HKWorkout?
    if elapsedTime < 10 {
      builder.discardWorkout()
      savedWorkout = nil
    } else {
      savedWorkout = try await builder.finishWorkout()
    }
    session.end()

    // 3. Reset state (partial - keep heart rate zones)
    let zones = heartRateZones
    resetWorkout()
    heartRateZones = zones

    // 4. Start new session
    try await startWorkout(workoutConfiguration: newConfiguration, shouldMirror: false)

    return savedWorkout
  }

  func handleActiveWorkoutRecovery() async throws {
    // Load heart rate zones from application context (synced from iOS)
    if let data = WatchChannel.shared.getApplicationContextData(for: WatchChannel.heartRateZonesKey),
       let zones = try? JSONDecoder.watch.decode(HeartRateZones.self, from: data) {
      heartRateZones = zones
    }

    session = try await healthStore.recoverActiveWorkoutSession()

    builder = session?.associatedWorkoutBuilder()
    session?.delegate = self
    builder?.delegate = self
    builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: session?.workoutConfiguration)
  }
}

// MARK: - HKLiveWorkoutBuilderDelegate
// HealthKit calls the delegate methods on an anonymous serial background queue,
// so the methods need to be nonisolated explicitly.
//
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
  nonisolated public func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
    /**
     HealthKit calls this method on an anonymous serial background queue.
     Use Task to provide an asynchronous context so MainActor can come to play.
     */
    Task { @MainActor in
      var allStatistics: [HKStatistics] = []
      
      for type in collectedTypes {
        if let quantityType = type as? HKQuantityType, let statistics = workoutBuilder.statistics(for: quantityType) {
          updateForStatistics(statistics)
          allStatistics.append(statistics)
        }
      }
      
      let archivedData = try? NSKeyedArchiver.archivedData(withRootObject: allStatistics, requiringSecureCoding: true)
      guard let archivedData = archivedData, !archivedData.isEmpty else {
        print("Encoded cycling data is empty")
        return
      }
      /**
       Send a Data object to the connected remote workout session.
       */
      await sendData(archivedData)
    }
  }
  
  nonisolated public func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
  }
}
#endif
