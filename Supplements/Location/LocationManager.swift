//
//  LocationManager.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-23.
//

import Foundation
@preconcurrency import CoreLocation

final actor LocationManager: NSObject {
    static let shared = LocationManager()

    @AsyncStreamable private(set) var currentLocation: CLLocation?

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let locationManagerDelegate = LocationManagerDelegate()

    private override init() {
        super.init()

        locationManagerDelegate.onAuthentication = { [weak self] in
            await self?.startMonitoring()
        }
        locationManagerDelegate.onNewLocation = { [weak self] location in
            await self?.set(currentLocation: location)
        }

        locationManager.delegate = locationManagerDelegate
    }
}

extension LocationManager {

    func requestAuth() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            startMonitoring()
        default:
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func startMonitoring() {
        guard
            CLLocationManager.significantLocationChangeMonitoringAvailable(),
            locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse
        else {
            print("Failed to start location monitoring")
            return
        }

        locationManager.startMonitoringSignificantLocationChanges()
    }

    func stopMonitoring() {
        locationManager.stopMonitoringSignificantLocationChanges()
    }

    func set(currentLocation: CLLocation) {
        self.currentLocation = currentLocation
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

private final class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {

    var onAuthentication: @Sendable () async -> Void = { }
    var onNewLocation: @Sendable (CLLocation) async -> Void = { _ in }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let onAuthenticationCopy = onAuthentication
        Task {
            await onAuthenticationCopy()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        let onNewLocationCopy = onNewLocation
        Task {
            await onNewLocationCopy(newLocation)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
    }
}
