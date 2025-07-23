//
//  DayReviewWeatherCalculator.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-23.
//

import Foundation
@preconcurrency import WeatherKit
import CoreLocation

final actor DayReviewWeatherCalculator {
  static let shared = DayReviewWeatherCalculator()

  private init() { }
}

extension DayReviewWeatherCalculator {

  func calculateWeatherDataString(for date: Date) async throws -> String {
    let weatherData = await calculateWeatherData(for: date)
    let jsonData = try JSONEncoder.bloomModel.encode(weatherData)
    return String(data: jsonData, encoding: .utf8) ?? "{}"
  }

  func calculateWeatherData(for date: Date) async -> DayReviewWeatherData? {
    guard let location = await getCurrentLocation() else {
      return nil
    }

    guard let weather = await WeatherForecaster.shared.forecastedWeather(location: location) else {
      return nil
    }

    let currentConditions = CurrentWeatherConditions(
      temperature: weather.currentWeather.temperature.formatted(
        .measurement(
          width: .narrow,
          numberFormatStyle: .number.precision(.fractionLength(0))
        )
      ),
      condition: weather.currentWeather.condition.description,
      symbolName: weather.currentWeather.symbolName,
      humidity: formatHumidity(weather.currentWeather.humidity),
      windSpeed: formatWindSpeed(weather.currentWeather.wind.speed)
    )

    let hourlyForecast = weather.hourlyForecast.prefix(24).map { hourWeather in
      HourlyWeatherForecast(
        hour: hourWeather.date,
        temperature: hourWeather.temperature.formatted(
          .measurement(
            width: .narrow,
            numberFormatStyle: .number.precision(.fractionLength(0))
          )
        ),
        condition: hourWeather.condition.description,
        symbolName: hourWeather.symbolName,
        humidity: formatHumidity(hourWeather.humidity),
        windSpeed: formatWindSpeed(hourWeather.wind.speed)
      )
    }

    return DayReviewWeatherData(
      currentConditions: currentConditions,
      hourlyForecast: Array(hourlyForecast)
    )
  }
}

private extension DayReviewWeatherCalculator {

  func getCurrentLocation() async -> CLLocation? {
    let locationManager = await LocationManagerViewModel.shared
    await locationManager.requestLocation()

    let timeout: UInt64 = 2_000_000_000 // 2 seconds
    let interval: UInt64 = 100_000_000 // 100ms
    var waited: UInt64 = 0

    while await locationManager.currentLocation == nil && waited < timeout {
      try? await Task.sleep(nanoseconds: interval)
      waited += interval
    }

    return await locationManager.currentLocation
  }

  func formatHumidity(_ humidity: Double) -> String? {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: humidity))
  }

  func formatWindSpeed(_ windSpeed: Measurement<UnitSpeed>) -> String? {
    return windSpeed.formatted(
      .measurement(
        width: .narrow,
        numberFormatStyle: .number.precision(.fractionLength(0))
      )
    )
  }
}
