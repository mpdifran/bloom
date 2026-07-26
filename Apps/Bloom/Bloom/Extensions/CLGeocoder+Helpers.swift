//
//  CLGeocoder+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-19.
//

import CoreLocation

// NOTE: CLGeocoder is deprecated as of iOS 26, but intentionally kept.
// The MapKit replacement (MKReverseGeocodingRequest) only exposes string address
// representations (cityWithContext / regionName) — it drops structured fields we rely on
// (isoCountryCode, administrativeArea). CLGeocoder still works; revisit if MapKit gains
// structured access. The deprecation warnings here are expected.

extension CLGeocoder {

    func getCountry(from location: CLLocation) async throws -> String? {
        let placemarks = try await reverseGeocodeLocation(location)

        if let placemark = placemarks.first {
            let country = placemark.country // Full country name (e.g., "United States")
            let countryCode = placemark.isoCountryCode // ISO code (e.g., "US")

            return country ?? countryCode
        }
        return nil
    }
}
