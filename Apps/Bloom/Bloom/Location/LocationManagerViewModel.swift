//
//  LocationManagerViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-16.
//

import SwiftUI
import CoreLocation
import BloomFoundation
import AppUI

extension CLAuthorizationStatus {
  var hasAccess: Bool {
    switch self {
    case .authorizedAlways, .authorizedWhenInUse:
      true
    default:
      false
    }
  }
}

@MainActor
final class LocationManagerViewModel: ObservableObject {
  static let shared = LocationManagerViewModel()

  @Published private(set) var currentLocation: CLLocation?
  @Published private(set) var country: String?
  @Published private(set) var auth: CLAuthorizationStatus = .notDetermined

  private init() {
    locationManagerDelegate = LocationManagerDelegate(actor: self)
    locationManager.delegate = locationManagerDelegate
  }

  private let locationManager = CLLocationManager()

  private var locationManagerDelegate: LocationManagerDelegate? = nil
  private var tasks = [Task<Void, Never>]()
}

extension LocationManagerViewModel {

  func checkPermission() {
    self.auth = locationManager.authorizationStatus
  }

  func promptForPermission(alertDetails: Binding<AlertDetails?>) {
    checkPermission()

    switch locationManager.authorizationStatus {
    case .notDetermined:
      locationManager.requestWhenInUseAuthorization()
    case .denied:
      alertDetails.wrappedValue = permissionAlert
    case .restricted:
      alertDetails.wrappedValue = restrictionAlert
    case .authorizedAlways, .authorizedWhenInUse:
      break
    @unknown default:
      break
    }
  }

  func requestLocation() {
    locationManager.requestLocation()
  }

  func set(auth: CLAuthorizationStatus) {
    self.auth = auth
  }

  func set(currentLocation: CLLocation) {
    self.currentLocation = currentLocation
    Task {
      await self.determineCountry(for: currentLocation)
    }
  }

  func locality(for location: CLLocation) async -> String? {
    do {
      let geocoder = CLGeocoder()
      let placemarks = try await geocoder.reverseGeocodeLocation(location)

      return placemarks.first?.locality
    } catch {
      print(error)
    }
    return nil
  }
  
  func locationString() async -> String? {
    if currentLocation == nil {
      requestLocation()
      // Give location services a moment to update
      await Delay(500)
    }
    
    guard let location = currentLocation else {
      return nil
    }
    
    do {
      let geocoder = CLGeocoder()
      let placemarks = try await geocoder.reverseGeocodeLocation(location)
      
      guard let placemark = placemarks.first else {
        return nil
      }
      
      var components = [String]()
      
      // Add city
      if let city = placemark.locality {
        components.append(city)
      }
      
      // Add state/province
      if let state = placemark.administrativeArea {
        components.append(state)
      }
      
      // Add country
      if let country = placemark.country {
        components.append(country)
      }
      
      return components.isEmpty ? nil : components.joined(separator: ", ")
    } catch {
      print("Error geocoding location: \(error)")
      return nil
    }
  }
}

private extension LocationManagerViewModel {

  func determineCountry(for location: CLLocation) async {
    let geocoder = CLGeocoder()
    do {
        guard let country = try await geocoder.getCountry(from: location) else {
            return
        }
        // Map country names and codes to normalized country identifiers
        let normalizedCountry = country.lowercased()

        if normalizedCountry == "canada" || normalizedCountry == "ca" {
          self.country = "canada"
        } else if normalizedCountry == "united states" || normalizedCountry == "united states of america" || normalizedCountry == "us" || normalizedCountry == "usa" {
          self.country = "usa"
        } else {
          // For any other country, use the lowercase country name as the identifier
          self.country = normalizedCountry
        }
    } catch {
        print(error)
    }
  }

  var permissionAlert: AlertDetails {
    AlertDetails(
      title: "Location Sharing Denied",
      message: "Please allow location access in Settings.",
      buttons: [
        AlertDetails.Button(
          title: "Open Settings",
          action: { [weak self] in
            self?.openSettings()
          }
        ),
        AlertDetails.Button(
          title: "Cancel",
          role: .cancel
        ) { }
      ]
    )
  }

  var restrictionAlert: AlertDetails {
    AlertDetails(
      title: "Location Sharing Restricted",
      message: "Location sharing is restricted by Screen Time or parental controls. To enable access, have your parent or guardian allow Location sharing for this app in Screen Time settings.",
      buttons: [
        AlertDetails.Button(
          title: "OK",
          action: { }
        )
      ]
    )
  }

  func openSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
  }
}

private final class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {

  weak var actor: LocationManagerViewModel?

  init(actor: LocationManagerViewModel) {
    self.actor = actor
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    guard let actor else { return }

    let auth = manager.authorizationStatus

    Task.detached {
      await actor.set(auth: auth)
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard
      let newLocation = locations.last,
      let actor
    else { return }

    Task.detached {
      await actor.set(currentLocation: newLocation)
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("Location manager failed with error: \(error)")
  }
}
