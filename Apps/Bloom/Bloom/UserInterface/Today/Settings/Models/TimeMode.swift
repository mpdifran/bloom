//
//  TimeMode.swift
//  Bloom
//
//  Created by Assistant on 2025-08-27.
//

import Foundation
import SwiftUI
import SFSafeSymbols

enum TimeMode: String, CaseIterable, Identifiable, Codable {
  case morning = "morning"
  case afternoon = "afternoon"
  case evening = "evening"
  case night = "night"
  
  var id: String { rawValue }
  
  var displayName: String {
    switch self {
    case .morning:
      return "Morning"
    case .afternoon:
      return "Afternoon"
    case .evening:
      return "Evening"
    case .night:
      return "Night"
    }
  }
  
  var icon: SFSymbol {
    switch self {
    case .morning:
      return .sunriseFill
    case .afternoon:
      return .sunMaxFill
    case .evening:
      return .sunsetFill
    case .night:
      return .moonStarsFill
    }
  }
  
  var tintColor: Color {
    switch self {
    case .morning:
      return .mutedYellow
    case .afternoon:
      return .mutedOrange
    case .evening:
      return .mutedIndigo
    case .night:
      return .mutedBlue
    }
  }
  
  var defaultStartHour: Int {
    switch self {
    case .morning:
      return 6  // 6:00 AM
    case .afternoon:
      return 12 // 12:00 PM
    case .evening:
      return 17 // 5:00 PM
    case .night:
      return 22 // 10:00 PM
    }
  }
  
  static func current(for date: Date = .now, settings: TodaySettings) -> TimeMode {
    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: date)
    
    // Check in reverse order (night -> evening -> afternoon -> morning)
    // to find the most recent time mode that has started
    if hour >= settings.nightStartHour {
      return .night
    } else if hour >= settings.eveningStartHour {
      return .evening
    } else if hour >= settings.afternoonStartHour {
      return .afternoon
    } else if hour >= settings.morningStartHour {
      return .morning
    } else {
      // If before morning start (e.g., 3 AM), consider it night from previous day
      return .night
    }
  }
}
