//
//  TodaySection.swift
//  Bloom
//
//  Created by Assistant on 2025-08-27.
//

import SwiftUI
import SFSafeSymbols

enum TodaySection: String, CaseIterable, Identifiable, Codable {
  case todaysAdvice = "todaysAdvice"
  case insights = "insights"
  case sleepDetails = "sleepDetails"
  case tonightsSleep = "tonightsSleep"
  case phaseTip = "phaseTip"
  case periodForecast = "periodForecast"
  case goals = "goals"
  case reminders = "reminders"
  case todaysEvents = "todaysEvents"
  case tomorrowsEvents = "tomorrowsEvents"
  case todaysWeather = "todaysWeather"
  case tomorrowsWeather = "tomorrowsWeather"

  var id: String { rawValue }
  
  var displayName: String {
    switch self {
    case .todaysAdvice:
      return "Today's Advice"
    case .insights:
      return "Insights"
    case .sleepDetails:
      return "Sleep Details"
    case .tonightsSleep:
      return "Tonight's Sleep"
    case .phaseTip:
      return "Cycle Phase Tip"
    case .periodForecast:
      return "Period Forecast"
    case .goals:
      return "Goals"
    case .reminders:
      return "Reminders"
    case .todaysEvents:
      return "Today's Events"
    case .tomorrowsEvents:
      return "Tomorrow's Events"
    case .todaysWeather:
      return "Today's Weather"
    case .tomorrowsWeather:
      return "Tomorrow's Weather"
    }
  }
  
  var icon: SFSymbol {
    switch self {
    case .todaysAdvice:
      return .lightbulbFill
    case .insights:
      return .chartLineUptrendXyaxis
    case .sleepDetails:
      return .bedDoubleFill
    case .tonightsSleep:
      return .moonZzzFill
    case .phaseTip:
      return .sparkles
    case .periodForecast:
      return .calendarBadgeClock
    case .goals:
      return .target
    case .reminders:
      return .bellFill
    case .todaysEvents:
      return .calendar
    case .tomorrowsEvents:
      return .calendar
    case .todaysWeather:
      return .sunMaxFill
    case .tomorrowsWeather:
      return .cloudSunFill
    }
  }
  
  var defaultOrder: Int {
    switch self {
    case .todaysAdvice:
      return 0
    case .insights:
      return 1
    case .sleepDetails:
      return 2
    case .tonightsSleep:
      return 3
    case .phaseTip:
      return 4
    case .periodForecast:
      return 5
    case .goals:
      return 6
    case .reminders:
      return 7
    case .todaysEvents:
      return 8
    case .tomorrowsEvents:
      return 9
    case .todaysWeather:
      return 10
    case .tomorrowsWeather:
      return 11
    }
  }
  
  var requiresBloomPlus: Bool {
    switch self {
    case .goals, .reminders, .todaysEvents, .tomorrowsEvents, .todaysWeather, .tomorrowsWeather:
      false
    default:
      true
    }
  }

  var requiresFemale: Bool {
    switch self {
    case .phaseTip, .periodForecast:
      true
    default:
      false
    }
  }
}
