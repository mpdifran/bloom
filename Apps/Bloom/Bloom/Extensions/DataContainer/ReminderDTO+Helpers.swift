//
//  ReminderDTO+Helpers.swift
//  Bloom
//
//  Created by Assistant on 2025-06-04.
//

import SwiftUI
import DataContainer

public extension ReminderDTO {
  
  /// Returns the color for this reminder
  var color: Color {
    return Color(hex: colorHex) ?? .accentColor
  }
  
  /// Returns a combined description of all cadence types and times
  var combinedCadenceDescription: String {
    return occurrences.combinedCadenceDescription()
  }
}