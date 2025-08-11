import SwiftUI
import DataContainer
import HealthKit
import CoreHealth

extension Reminder {
  var color: Color {
    if colorHex.isEmpty {
      return .accentColor
    }
    return Color(hex: colorHex) ?? .accentColor
  }
  
  /// Returns a combined description of all cadence types and times
  var combinedCadenceDescription: String {
    guard let occurrences = occurrences else {
      return "No schedule set"
    }
    
    // Convert to DTOs and use the centralized logic
    let occurrenceDTOs = occurrences.map { $0.asDTO() }
    return occurrenceDTOs.combinedCadenceDescription()
  }
  
  /// Returns a brief description of the side effects this reminder will perform
  @MainActor
  var sideEffectDescription: String? {
    guard let sideEffects = sideEffects, !sideEffects.isEmpty else { return nil }
    
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
      @unknown default:
        return nil
      }
    }
    
    return descriptions.isEmpty ? nil : descriptions.joined(separator: ", ")
  }
  
  /// Returns a brief description of the trigger that will auto-complete this reminder
  var triggerDescription: String? {
    guard let triggerTypeString = triggerType,
          let trigger = ReminderTriggerType(rawValue: triggerTypeString) else { return nil }
    
    switch trigger {
    case .logWeight:
      return "Complete when log weight"
    case .logWater:
      return "Complete when log water"
    case .logBloodPressure:
      return "Complete when log blood pressure"
    case .logStrengthTraining:
      return "Complete when log strength training"
    case .logCardio:
      return "Complete when log cardio"
    case .logMobilityFlexibility:
      return "Complete when log mobility/flexibility"
    case .logHIIT:
      return "Complete when log HIIT"
    }
  }
}
