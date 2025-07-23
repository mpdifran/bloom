//
//  DayReviewWeatherData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-23.
//

import Foundation

struct DayReviewWeatherData: SendableNetworkModel {
  let currentConditions: CurrentWeatherConditions?
  let hourlyForecast: [HourlyWeatherForecast]
}

struct CurrentWeatherConditions: SendableNetworkModel {
  let temperature: String
  let condition: String
  let symbolName: String
  let humidity: String?
  let windSpeed: String?
}

struct HourlyWeatherForecast: SendableNetworkModel {
  let hour: Date
  let temperature: String
  let condition: String
  let symbolName: String
  let humidity: String?
  let windSpeed: String?
}