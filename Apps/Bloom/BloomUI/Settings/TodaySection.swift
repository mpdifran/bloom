//
//  TodaySection.swift
//  BloomUI
//
//  Created by Assistant on 2025-08-27.
//

import SwiftUI
import SFSafeSymbols

public enum TodaySection: String, CaseIterable, Identifiable, Codable {
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

  public var id: String { rawValue }

  public var displayName: String {
    switch self {
    case .todaysAdvice:
      return String(localized: "Today's Advice", bundle: Bundle.bloomUI)
    case .insights:
      return String(localized: "Insights", bundle: Bundle.bloomUI)
    case .sleepDetails:
      return String(localized: "Sleep Details", bundle: Bundle.bloomUI)
    case .tonightsSleep:
      return String(localized: "Tonight's Sleep", bundle: Bundle.bloomUI)
    case .phaseTip:
      return String(localized: "Cycle Phase Tip", bundle: Bundle.bloomUI)
    case .periodForecast:
      return String(localized: "Period Forecast", bundle: Bundle.bloomUI)
    case .goals:
      return String(localized: "Goals", bundle: Bundle.bloomUI)
    case .reminders:
      return String(localized: "Reminders", bundle: Bundle.bloomUI)
    case .todaysEvents:
      return String(localized: "Today's Events", bundle: Bundle.bloomUI)
    case .tomorrowsEvents:
      return String(localized: "Tomorrow's Events", bundle: Bundle.bloomUI)
    case .todaysWeather:
      return String(localized: "Today's Weather", bundle: Bundle.bloomUI)
    case .tomorrowsWeather:
      return String(localized: "Tomorrow's Weather", bundle: Bundle.bloomUI)
    }
  }

  public var icon: SFSymbol {
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

  public var defaultOrder: Int {
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

  public var requiresBloomPlus: Bool {
    switch self {
    case .goals, .reminders, .todaysEvents, .tomorrowsEvents, .todaysWeather, .tomorrowsWeather:
      false
    default:
      true
    }
  }

  public var requiresFemale: Bool {
    switch self {
    case .phaseTip, .periodForecast:
      true
    default:
      false
    }
  }
}
