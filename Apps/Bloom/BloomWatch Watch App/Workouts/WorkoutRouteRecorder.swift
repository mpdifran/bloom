//
//  WorkoutRouteRecorder.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-02-16.
//

import CoreLocation
import HealthKit

@MainActor
final class WorkoutRouteRecorder {
  static let shared = WorkoutRouteRecorder()

  private var routeBuilder: HKWorkoutRouteBuilder?
  private let healthStore = HKHealthStore()
  private let locationManager = LocationManager.shared

  private init() {}

  var isRecording: Bool {
    routeBuilder != nil
  }

  func startRecording() {
    routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)

    locationManager.onLocationsUpdated = { [weak self] locations in
      self?.handleLocations(locations)
    }
    locationManager.startUpdatingLocation()
  }

  func stopRecording(workout: HKWorkout) async {
    locationManager.stopUpdatingLocation()

    guard let routeBuilder else { return }
    self.routeBuilder = nil

    do {
      try await routeBuilder.finishRoute(with: workout, metadata: nil)
    } catch {
      print("Failed to finish workout route: \(error)")
    }
  }

  func cancelRecording() {
    locationManager.stopUpdatingLocation()
    routeBuilder?.discard()
    routeBuilder = nil
  }

  private func handleLocations(_ locations: [CLLocation]) {
    let filtered = locations.filter { $0.horizontalAccuracy <= 50.0 }
    guard !filtered.isEmpty, let routeBuilder else { return }

    routeBuilder.insertRouteData(filtered) { success, error in
      if let error {
        print("Failed to insert route data: \(error)")
      }
    }
  }
}
