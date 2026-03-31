//
//  WorkoutManager.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-05.
//

import Foundation
import HealthKit
import Combine
import WatchConnectivity
import BloomFoundation

public enum WorkoutError: Error {
  case noActiveSession
}

@MainActor
public final class WorkoutManager: NSObject, ObservableObject {
  public static let shared = WorkoutManager()

  @Published public var workout: HKWorkout?
  @Published public var sessionState: HKWorkoutSessionState = .notStarted
  @Published public var isSwitchingWorkout = false
  @Published public var completedSegments: [CompletedWorkoutSegment] = []
  @Published public var isMirroring = false
  @Published public var heartRate: Double = 0
  @Published public var activeEnergy: Double = 0
  @Published public var speed: Double = 0
  @Published public var power: Double = 0
  @Published public var cadence: Double = 0
  @Published public var distance: Double = 0
  @Published public var water: Double = 0
  @Published public var elapsedTimeInterval: TimeInterval = 0

  // Zone tracking
  @Published public var heartRateZones: HeartRateZones?
  @Published public var zoneDurations: [TimeInterval] = [0, 0, 0, 0, 0, 0] // indices 0-5
  @Published public var currentZone: Int = 0

  private var lastHeartRateDate: Date?

  public let healthStore = HKHealthStore()
  internal(set) public var session: HKWorkoutSession?

  private override init() {
    super.init()
    Task {
      for await value in asynStreamTuple.stream {
        await consumeSessionStateChange(value)
      }
    }
  }

  /// Creates an async stream that buffers a single newest element, and the stream's continuation to yield new elements synchronously to the stream.
  /// The Swift actors don't handle tasks in a first-in-first-out way. Use AsyncStream to make sure that the app presents the latest state.
  private let asynStreamTuple = AsyncStream.makeStream(of: WorkoutSessionSateChange.self, bufferingPolicy: .bufferingNewest(1))

#if os(watchOS)
  internal(set) public var builder: HKLiveWorkoutBuilder?
#else
  /// A date for synchronizing the elapsed time between iOS and watchOS.
  var contextDate: Date?
#endif
}

public extension WorkoutManager {

  func resetWorkout() {
#if os(watchOS)
    builder = nil
#endif
    workout = nil
    session = nil
    activeEnergy = 0
    heartRate = 0
    distance = 0
    water = 0
    power = 0
    cadence = 0
    speed = 0
    sessionState = .notStarted
    isMirroring = false

    // Reset zone tracking (preserve heartRateZones — they persist across workouts)
    zoneDurations = [0, 0, 0, 0, 0, 0]
    currentZone = 0
    lastHeartRateDate = nil
  }

  var isMultiWorkoutSession: Bool {
    completedSegments.count > 1
  }

  func sendData(_ data: Data) async {
    guard isMirroring else { return }
    do {
      try await session?.sendToRemoteWorkoutSession(data: data)
    } catch {
      print("Failed to send data: \(error)")
    }
  }
}

private extension WorkoutManager {

  func consumeSessionStateChange(_ change: WorkoutSessionSateChange) async {
    sessionState = change.newState
    print("Updated session to \(sessionState.name).")
    /**
     Wait for the session to transition states before ending the builder.
     */
#if os(watchOS)
    /**
     Send the elapsed time to the iOS side.
     */
    let elapsedTimeInterval = session?.associatedWorkoutBuilder().elapsedTime(at: change.date) ?? 0
    let elapsedTime = WorkoutElapsedTime(timeInterval: elapsedTimeInterval, date: change.date)
    if let elapsedTimeData = try? JSONEncoder().encode(elapsedTime) {
      await sendData(elapsedTimeData)
    }

    guard change.newState == .stopped, let builder else {
      return
    }

    let finishedWorkout: HKWorkout?
    do {
      try await builder.endCollection(at: change.date)

      // Discard workouts shorter than 15 seconds
      if elapsedTimeInterval < 15 {
        builder.discardWorkout()
        session?.end()
        return
      }

      finishedWorkout = try await builder.finishWorkout()
      session?.end()
    } catch {
      print("Failed to end workout: \(error))")
      return
    }
    workout = finishedWorkout
    if let finishedWorkout {
      let segment = CompletedWorkoutSegment(workout: finishedWorkout, zoneDurations: zoneDurations)
      completedSegments.append(segment)
    }
#endif
  }
}

extension WorkoutManager {

  func updateForStatistics(_ statistics: HKStatistics) {
    switch statistics.quantityType {
    case HKQuantityType.quantityType(forIdentifier: .heartRate):
      let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
      let newHeartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0

      // Track zone time - matches WorkoutHeartRateReport.swift calculation
      if heartRateZones != nil, let lastDate = lastHeartRateDate {
        let duration = statistics.endDate.timeIntervalSince(lastDate)
        if duration > 0 {
          zoneDurations[currentZone] += duration
        }
      }

      lastHeartRateDate = statistics.endDate
      currentZone = zone(forHeartRate: newHeartRate)
      heartRate = newHeartRate

    case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
      let energyUnit = HKUnit.kilocalorie()
      activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0

    case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
      HKQuantityType.quantityType(forIdentifier: .distanceCycling):
      let meterUnit = HKUnit.meter()
      distance = statistics.sumQuantity()?.doubleValue(for: meterUnit) ?? 0

    case HKQuantityType(.cyclingSpeed):
      let speedUnit = HKUnit.mile().unitDivided(by: HKUnit.hour())
      speed = statistics.mostRecentQuantity()?.doubleValue(for: speedUnit) ?? 0

    case HKQuantityType(.cyclingPower):
      let powerUnit = HKUnit.watt()
      power = statistics.mostRecentQuantity()?.doubleValue(for: powerUnit) ?? 0

    case HKQuantityType(.cyclingCadence):
      let cadenceUnit = HKUnit.count().unitDivided(by: .minute())
      cadence = statistics.mostRecentQuantity()?.doubleValue(for: cadenceUnit) ?? 0

    default:
      return
    }
  }
}

extension WorkoutManager: HKWorkoutSessionDelegate {

  nonisolated public func workoutSession(
    _ workoutSession: HKWorkoutSession,
    didChangeTo toState: HKWorkoutSessionState,
    from fromState: HKWorkoutSessionState,
    date: Date
  ) {
    /**
     Yield the new state change to the async stream synchronously.
     asynStreamTuple is a constant, so it's nonisolated.
     */
    let sessionSateChange = WorkoutSessionSateChange(newState: toState, date: date)
    asynStreamTuple.continuation.yield(sessionSateChange)
  }

  nonisolated public func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
    print("Event Generated: \(event)")
  }

  nonisolated public func workoutSession(
    _ workoutSession: HKWorkoutSession,
    didFailWithError error: Error
  ) {
    print("\(#function): \(error)")
  }

  /**
   HealthKit calls this method when it determines that the mirrored workout session is invalid.
   */
  nonisolated public func workoutSession(
    _ workoutSession: HKWorkoutSession,
    didDisconnectFromRemoteDeviceWithError error: Error?
  ) {
    if let error {
      print("\(#function): \(error)")
    }
  }

  /**
   In iOS, the sample app can go into the background and become suspended.
   When suspended, HealthKit gathers the data coming from the remote session.
   When the app resumes, HealthKit sends an array containing all the data objects it has accumulated to this delegate method.
   The data objects in the array appear in the order that the local system received them.

   On watchOS, the workout session keeps the app running even if it is in the background; however, the system can
   temporarily suspend the app — for example, if the app uses an excessive amount of CPU in the background.
   While suspended, HealthKit caches the incoming data objects and delivers an array of data objects when the app resumes, just like in the iOS app.
   */
  nonisolated public func workoutSession(
    _ workoutSession: HKWorkoutSession,
    didReceiveDataFromRemoteWorkoutSession data: [Data]
  ) {
    print("\(#function): \(data.debugDescription)")
    Task { @MainActor in
      do {
        for anElement in data {
          try handleReceivedData(anElement)
        }
      } catch {
        print("Failed to handle received data: \(error))")
      }
    }
  }
}

// MARK: - Zone Tracking

public extension WorkoutManager {

  /// Weighted zone minutes (zones 3-4 = 2x, zone 5 = 3x)
  var totalZoneMinutes: Double {
    let z1 = zoneDurations[1] / 60.0
    let z2 = zoneDurations[2] / 60.0
    let z3 = zoneDurations[3] / 60.0
    let z4 = zoneDurations[4] / 60.0
    let z5 = zoneDurations[5] / 60.0

    return z1 + z2 + (z3 * .zone34Multiplier) + (z4 * .zone34Multiplier) + (z5 * .zone5Multiplier)
  }

  func zone(forHeartRate bpm: Double) -> Int {
    guard let zones = heartRateZones else { return 0 }

    if bpm < zones.zone1 { return 0 }
    else if bpm < zones.zone2 { return 1 }
    else if bpm < zones.zone3 { return 2 }
    else if bpm < zones.zone4 { return 3 }
    else if bpm < zones.zone5 { return 4 }
    else { return 5 }
  }
}
