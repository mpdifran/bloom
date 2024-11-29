//
//  CLGeocoder+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-19.
//

import CoreLocation

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
