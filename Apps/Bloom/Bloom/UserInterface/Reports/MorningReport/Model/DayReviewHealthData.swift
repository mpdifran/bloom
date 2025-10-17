//
//  DayReviewHealthData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-22.
//

import Foundation
import CoreNetwork

struct DayReviewHealthData: SendableNetworkModel {
  let demographics: HealthVitalData.UserInfo?
  let vitals: DayVitalsData?
  let goalProgress: GoalProgressData?
  let weather: DayReviewWeatherData?
  let simplifiedWeather: SimplifiedWeatherData?
  let events: DayReviewEventData?
}
