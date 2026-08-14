//
//  TimeMode.swift
//  BloomUI
//
//  Created by Assistant on 2025-08-27.
//

import Foundation
import SwiftUI
import SFSafeSymbols
import BloomFoundation

public enum TimeMode: String, CaseIterable, Identifiable, Codable {
  case morning = "morning"
  case afternoon = "afternoon"
  case evening = "evening"
  case night = "night"

  public var id: String { rawValue }

  public var displayName: String {
    switch self {
    case .morning:
      return String(localized: "Morning", bundle: Bundle.bloomUI, comment: "Display name for time mode")
    case .afternoon:
      return String(localized: "Afternoon", bundle: Bundle.bloomUI, comment: "Display name for time mode")
    case .evening:
      return String(localized: "Evening", bundle: Bundle.bloomUI, comment: "Display name for time mode")
    case .night:
      return String(localized: "Night", bundle: Bundle.bloomUI, comment: "Display name for time mode")
    }
  }

  public var icon: SFSymbol {
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

  public var tintColor: Color {
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

  public var defaultStartHour: Int {
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

  public static func current(for date: Date = .now, settings: any TimeModeSettings) -> TimeMode {
    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: date)
    let minute = calendar.component(.minute, from: date)

    // Convert to minutes since midnight for accurate comparison
    let currentMinutes = hour * 60 + minute

    let morningMinutes = settings.morningStartHour * 60 + settings.morningStartMinute
    let afternoonMinutes = settings.afternoonStartHour * 60 + settings.afternoonStartMinute
    let eveningMinutes = settings.eveningStartHour * 60 + settings.eveningStartMinute
    let nightMinutes = settings.nightStartHour * 60 + settings.nightStartMinute

    // Check in reverse order (night -> evening -> afternoon -> morning)
    // to find the most recent time mode that has started
    if currentMinutes >= nightMinutes {
      return .night
    } else if currentMinutes >= eveningMinutes {
      return .evening
    } else if currentMinutes >= afternoonMinutes {
      return .afternoon
    } else if currentMinutes >= morningMinutes {
      return .morning
    } else {
      // If before morning start (e.g., 3 AM), consider it night from previous day
      return .night
    }
  }
}

/// Protocol that defines the start times for each time mode phase
public protocol TimeModeSettings {
  var morningStartHour: Int { get }
  var afternoonStartHour: Int { get }
  var eveningStartHour: Int { get }
  var nightStartHour: Int { get }

  var morningStartMinute: Int { get }
  var afternoonStartMinute: Int { get }
  var eveningStartMinute: Int { get }
  var nightStartMinute: Int { get }
}
