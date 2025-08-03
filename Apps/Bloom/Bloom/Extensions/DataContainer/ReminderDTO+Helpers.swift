//
//  ReminderDTO+Helpers.swift
//  Bloom
//
//  Created by Assistant on 2025-06-04.
//

import SwiftUI
import DataContainer
import HealthKit
import CoreHealth

public extension ReminderDTO {
  
  /// Returns the color for this reminder
  var color: Color {
    return Color(hex: colorHex) ?? .accentColor
  }
  
  /// Returns a combined description of all cadence types and times
  var combinedCadenceDescription: String {
    return occurrences.combinedCadenceDescription()
  }
  
  /// Returns a brief description of the side effects this reminder will perform
  @MainActor
  var sideEffectDescription: String? {
    guard !sideEffects.isEmpty else { return nil }
    
    let descriptions = sideEffects.compactMap { sideEffect -> String? in
      switch sideEffect.type {
      case .logFood:
        if let config = sideEffect.decodeConfiguration(as: LogFoodSideEffectConfig.self) {
          return "Log \(config.foodItemName)"
        }
        return nil
      case .logWater:
        if let config = sideEffect.decodeConfiguration(as: LogWaterSideEffectConfig.self) {
          let unit = HKUnit(from: config.unitString)
          let quantity = HKQuantity(unit: unit, doubleValue: config.amount)
          return "Log \(quantity.displayString(for: unit)) of water"
        }
        return nil
      case .none:
        return nil
      @unknown default:
        return nil
      }
    }
    
    return descriptions.isEmpty ? nil : descriptions.joined(separator: ", ")
  }
}
