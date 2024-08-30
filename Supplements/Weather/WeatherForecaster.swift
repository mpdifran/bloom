//
//  WeatherForecaster.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-29.
//

import Foundation
import WeatherKit
import CoreLocation

final class WeatherForecaster: Sendable {
    static let shared = WeatherForecaster()

    let weatherService = WeatherService()

    private init() { }
}

extension WeatherForecaster {

    func forecastedWeather(location: CLLocation) async -> Weather? {
        do {
            print("Fetching Weather")
            return try await weatherService.weather(for: location)
        } catch {
            print(error)
        }
        return nil
    }
}
