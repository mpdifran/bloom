//
//  LocationManager.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-23.
//

import Foundation
import CoreLocation

final class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    @Published private(set) var currentLocation: CLLocation?

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private override init() {
        super.init()

        locationManager.delegate = self
    }
}

extension LocationManager {

    func requestAuth() {
        print("Requesting Auth")
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            startMonitoring()
        default:
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func startMonitoring() {
        print("Attempting to start location monitoring")
        guard
            CLLocationManager.significantLocationChangeMonitoringAvailable(),
            locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse
        else {
            print("Failed to start location monitoring")
            return
        }

        print("Starting location monitoring")
        locationManager.startMonitoringSignificantLocationChanges()
    }

    func stopMonitoring() {
        print("Stopping location monitoring")
        locationManager.stopMonitoringSignificantLocationChanges()
    }

    func locality(for location: CLLocation) async -> String? {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)

            return placemarks.first?.locality
        } catch {
            print(error)
        }
        return nil
    }
}

extension LocationManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        startMonitoring()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        currentLocation = newLocation
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
    }
}
