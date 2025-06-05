import SwiftUI
import DataContainer

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
}