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

  private let locationManager = CLLocationManager()

  private override init() {
    super.init()
    locationManager.delegate = self
    authorizationStatus = locationManager.authorizationStatus
  }

  func requestWhenInUseAuthorization() {
    locationManager.requestWhenInUseAuthorization()
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
}
