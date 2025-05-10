//
//  WorkoutManager+watchOS.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-05.
//

import Foundation
import HealthKit

#if os(watchOS)
public extension WorkoutManager {
  
  func startWorkout(workoutConfiguration: HKWorkoutConfiguration, shouldMirror: Bool) async throws {
    session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
    builder = session?.associatedWorkoutBuilder()
    session?.delegate = self
    builder?.delegate = self
    builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: workoutConfiguration)

    try await session?.prepare() // ChatGPT said this is important to do before trying to mirror.

    /**
     Start mirroring the session to the companion device.
     */
    if shouldMirror {
      try await session?.startMirroringToCompanionDevice()
    }
    /**
     Start the workout session activity.
     */
    let startDate = Date()
    session?.startActivity(with: startDate)
    try await builder?.beginCollection(at: startDate)
    print("Started session")
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

  func handleActiveWorkoutRecovery() async throws {
    let session = try await healthStore.recoverActiveWorkoutSession()

    builder = session?.associatedWorkoutBuilder()
    session?.delegate = self
    builder?.delegate = self
    builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: workoutConfiguration)
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
