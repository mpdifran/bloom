//
//  LocationManager.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-26.
//

import CoreLocation

@MainActor
final class LocationManager: NSObject, ObservableObject {
  static let shared = LocationManager()

  @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

  var onLocationsUpdated: (([CLLocation]) -> Void)?

  private let locationManager = CLLocationManager()

  private override init() {
    super.init()
    locationManager.delegate = self
    authorizationStatus = locationManager.authorizationStatus
  }

  func requestWhenInUseAuthorization() {
    locationManager.requestWhenInUseAuthorization()
  }

  func startUpdatingLocation() {
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.startUpdatingLocation()
  }

  func stopUpdatingLocation() {
    locationManager.stopUpdatingLocation()
    onLocationsUpdated = nil
  }

  var isAuthorized: Bool {
    authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
  }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    Task { @MainActor in
      self.authorizationStatus = manager.authorizationStatus
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    Task { @MainActor in
      self.onLocationsUpdated?(locations)
    }
  }
}
