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

  func calculateSimplifiedWeatherDataString(for date: Date) async throws -> String {
    let weatherData = await calculateSimplifiedWeatherData(for: date)
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

  func calculateSimplifiedWeatherData(for date: Date) async -> SimplifiedWeatherData? {
    guard let location = await getCurrentLocation() else {
      return nil
    }

    guard let weather = await WeatherForecaster.shared.forecastedWeather(location: location) else {
      return nil
    }

    // Get today's forecast for high/low temperatures
    let todaysForecast = weather.hourlyForecast.filter { hourWeather in
      Calendar.current.isDate(hourWeather.date, inSameDayAs: date)
    }

    let todaysHigh = todaysForecast.max { first, second in
      first.temperature.value < second.temperature.value
    }?.temperature.formatted(
      .measurement(
        width: .narrow,
        numberFormatStyle: .number.precision(.fractionLength(0))
      )
    )

    let todaysLow = todaysForecast.min { first, second in
      first.temperature.value < second.temperature.value
    }?.temperature.formatted(
      .measurement(
        width: .narrow,
        numberFormatStyle: .number.precision(.fractionLength(0))
      )
    )

    // Determine general outlook and significant weather
    let generalOutlook = determineGeneralOutlook(from: weather.currentWeather.condition)
    let hasSignificantWeather = hasSignificantWeatherConditions(weather: weather)

    return SimplifiedWeatherData(
      currentTemperature: weather.currentWeather.temperature.formatted(
        .measurement(
          width: .narrow,
          numberFormatStyle: .number.precision(.fractionLength(0))
        )
      ),
      currentCondition: weather.currentWeather.condition.description,
      todaysHigh: todaysHigh,
      todaysLow: todaysLow,
      generalOutlook: generalOutlook,
      hasSignificantWeather: hasSignificantWeather
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

  func determineGeneralOutlook(from condition: WeatherKit.WeatherCondition) -> String {
    switch condition {
    case .clear, .mostlyClear, .partlyCloudy:
      return "sunny"
    case .cloudy, .mostlyCloudy:
      return "cloudy"
    case .rain, .drizzle, .heavyRain:
      return "rainy"
    case .snow, .sleet, .freezingRain, .heavySnow:
      return "snowy"
    case .thunderstorms:
      return "stormy"
    case .haze:
      return "foggy"
    default:
      return "variable"
    }
  }

  func hasSignificantWeatherConditions(weather: WeatherKit.Weather) -> Bool {
    // Check for significant weather in current conditions or forecast
    let significantConditions: [WeatherKit.WeatherCondition] = [
      .heavyRain, .thunderstorms, .heavySnow, .freezingRain, .sleet
    ]

    // Check current weather
    if significantConditions.contains(weather.currentWeather.condition) {
      return true
    }

    // Check next 12 hours for significant weather
    let next12Hours = weather.hourlyForecast.prefix(12)
    return next12Hours.contains { hour in
      significantConditions.contains(hour.condition)
    }
  }
}
