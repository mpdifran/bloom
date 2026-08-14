//
//  CelebrationKind.swift
//  Bloom
//
//  Created by Claude on 2026-02-26.
//

import SwiftUI
import CoreHealth

enum CelebrationKind: Equatable {
  case biologicalAge(yearsYounger: Int)
  case goalStreak(metricName: String, days: Int)
  case zoneMinutes(minutes: Int)
  case perfectSleep(SleepAnalysis)

  static func == (lhs: CelebrationKind, rhs: CelebrationKind) -> Bool {
    switch (lhs, rhs) {
    case (.biologicalAge(let l), .biologicalAge(let r)):
      return l == r
    case (.goalStreak(let lName, let lDays), .goalStreak(let rName, let rDays)):
      return lName == rName && lDays == rDays
    case (.zoneMinutes(let l), .zoneMinutes(let r)):
      return l == r
    case (.perfectSleep, .perfectSleep):
      return true
    default:
      return false
    }
  }
}

extension CelebrationKind {

  var telemetryName: String {
    switch self {
    case .biologicalAge: "biologicalAge"
    case .goalStreak(let metricName, let days): "goalStreak.\(metricName).\(days)days"
    case .zoneMinutes(let minutes): "zoneMinutes.\(minutes)"
    case .perfectSleep: "perfectSleep"
    }
  }

  var achievementIdentifier: String {
    switch self {
    case .biologicalAge(let yearsYounger):
      return "biologicalAge.\(yearsYounger)"
    case .goalStreak(let metricName, let days):
      return "goalStreak.\(metricName).\(days)"
    case .zoneMinutes(let minutes):
      return "zoneMinutes.\(minutes)"
    case .perfectSleep:
      return "perfectSleep"
    }
  }

  var title: String {
    switch self {
    case .biologicalAge(let yearsYounger):
      if yearsYounger == 1 {
        return String(localized: "1 Year Younger!", comment: "Title for celebration kind")
      }
      return "\(yearsYounger) Years Younger!"
    case .goalStreak(let metricName, let days):
      return "\(days)-Day \(metricName) Streak!"
    case .zoneMinutes(let minutes):
      return "\(minutes) Zone Minutes!"
    case .perfectSleep:
      return String(localized: "Perfect Sleep Score!", comment: "Title for celebration kind")
    }
  }

  var subtitle: String {
    switch self {
    case .biologicalAge(let yearsYounger):
      if yearsYounger == 1 {
        return String(localized: "Your biological age is 1 year younger than your actual age. Keep it up!", comment: "Subtitle for celebration kind")
      }
      return "Your biological age is \(yearsYounger) years younger than your actual age. Amazing!"
    case .goalStreak(_, let days):
      return "You've hit your goal \(days) days in a row. That's incredible consistency!"
    case .zoneMinutes(let minutes):
      if minutes >= 300 {
        return "You crushed the weekly recommended zone minutes with \(minutes)+ minutes. Outstanding effort!"
      }
      return "You hit the weekly recommended \(minutes) zone minutes. Great work staying active!"
    case .perfectSleep:
      return String(localized: "You scored a perfect 100 on your sleep score. That's as good as it gets!", comment: "Subtitle for celebration kind")
    }
  }

  var budImage: ImageResource {
    switch self {
    case .biologicalAge:
      .budCelebrationAge
    case .goalStreak:
      .budCelebrationGoal
    case .zoneMinutes(let minutes):
      minutes >= 300 ? .budCelebrationZoneMinHigh : .budCelebrationZoneMin
    case .perfectSleep:
      .budCelebrationSleep
    }
  }

  func shareSubtitle(name: String) -> String {
    switch self {
    case .biologicalAge(let yearsYounger):
      if name.isEmpty {
        return "Your biological age is \(yearsYounger) years younger."
      }
      return "\(name)'s biological age is \(yearsYounger) years younger."
    case .goalStreak(let metricName, let days):
      if name.isEmpty {
        return "You hit a \(days)-day \(metricName) streak."
      }
      return "\(name) hit a \(days)-day \(metricName) streak."
    case .zoneMinutes(let minutes):
      if name.isEmpty {
        return "You earned \(minutes) Zone Minutes this week."
      }
      return "\(name) earned \(minutes) Zone Minutes this week."
    case .perfectSleep:
      if name.isEmpty {
        return "You scored a perfect 100 on your sleep score."
      }
      return "\(name) scored a perfect 100 on their sleep score."
    }
  }

  func shareMessage() -> String {
    switch self {
    case .biologicalAge(let yearsYounger):
      return "My biological age is \(yearsYounger) years younger!"
    case .goalStreak(let metricName, let days):
      return "I hit a \(days)-day \(metricName) streak!"
    case .zoneMinutes(let minutes):
      return "I earned \(minutes) Zone Minutes this week!"
    case .perfectSleep:
      return "I scored a perfect 100 on my sleep score!"
    }
  }
}
