//
//  Array+ReminderOccurrenceDTO.swift
//  DataContainer
//
//  Created by Assistant on 2025-06-05.
//

import Foundation
import BloomFoundation

public extension Array where Element == ReminderOccurrenceDTO {
  
  /// Returns a combined description of all cadence types and times
  func combinedCadenceDescription() -> String {
    guard !isEmpty else {
      return String(localized: "No schedule set", bundle: Bundle.dataContainer, comment: "Shown when a reminder has no occurrences configured")
    }
    
    // Group occurrences by cadence type
    let groupedOccurrences = Dictionary(grouping: self) { $0.cadenceType }
    
    let timeFormatter = DateFormatter()
    timeFormatter.timeStyle = .short
    timeFormatter.dateStyle = .none
    
    var descriptions: [String] = []
    
    // Process each cadence type in a specific order
    let orderedCadenceTypes: [ReminderCadenceType] = [.daily, .weekly, .monthly, .yearly]
    
    for cadenceType in orderedCadenceTypes {
      guard let occurrencesForType = groupedOccurrences[cadenceType], !occurrencesForType.isEmpty else { continue }
      
      if occurrencesForType.count == 1 {
        // Single occurrence - use the existing description
        descriptions.append(occurrencesForType[0].cadenceDescription)
      } else {
        // Multiple occurrences of the same cadence type
        let timeStrings = occurrencesForType.map { timeFormatter.string(from: $0.time) }.sorted()
        let combinedTimes = ListFormatter.main.string(from: timeStrings) ?? timeStrings.joined(separator: ", ")
        
        switch cadenceType {
        case .daily:
          descriptions.append(String(
            localized: "Daily, \(combinedTimes)",
            bundle: Bundle.dataContainer,
            comment: "Combined reminder cadence. The placeholder is a list of times of day."
          ))
        case .weekly:
          // For weekly, we need to check if they have the same days
          let allDaysOfWeek = occurrencesForType.compactMap { $0.daysOfWeek }.flatMap { $0 }
          let uniqueDays = Set(allDaysOfWeek)
          
          if occurrencesForType.allSatisfy({ $0.daysOfWeek == occurrencesForType.first?.daysOfWeek }) {
            // All occurrences have the same days of week
            let dayNames = uniqueDays.sorted().compactMap { Calendar.current.weekdaySymbols[safe: $0 - 1] }
            if dayNames.count == 7 {
              descriptions.append(String(
                localized: "Daily, \(combinedTimes)",
                bundle: Bundle.dataContainer,
                comment: "Combined reminder cadence. The placeholder is a list of times of day."
              ))
            } else if dayNames.count == 5 && Set([2, 3, 4, 5, 6]).isSubset(of: uniqueDays) {
              descriptions.append(String(
                localized: "Weekdays, \(combinedTimes)",
                bundle: Bundle.dataContainer,
                comment: "Combined reminder cadence for Monday through Friday. The placeholder is a list of times of day."
              ))
            } else if dayNames.count == 2 && Set([1, 7]).isSubset(of: uniqueDays) {
              descriptions.append(String(
                localized: "Weekends, \(combinedTimes)",
                bundle: Bundle.dataContainer,
                comment: "Combined reminder cadence for Saturday and Sunday. The placeholder is a list of times of day."
              ))
            } else {
              let formattedDays = ListFormatter.main.string(from: dayNames) ?? dayNames.joined(separator: ", ")
              descriptions.append(String(
                localized: "Every \(formattedDays), \(combinedTimes)",
                bundle: Bundle.dataContainer,
                comment: "Combined reminder cadence. Placeholders are a list of weekday names and a list of times of day."
              ))
            }
          } else {
            // Different days of week, show individual descriptions
            descriptions.append(contentsOf: occurrencesForType.map { $0.cadenceDescription })
          }
        case .monthly:
          // For monthly, check if they have the same day of month
          if occurrencesForType.allSatisfy({ $0.dayOfMonth == occurrencesForType.first?.dayOfMonth }) {
            if let dayOfMonth = occurrencesForType.first?.dayOfMonth {
              let ordinal = NumberFormatter.ordinal.string(for: dayOfMonth) ?? "\(dayOfMonth)"
              descriptions.append(String(
                localized: "Monthly on the \(ordinal), \(combinedTimes)",
                bundle: Bundle.dataContainer,
                comment: "Combined reminder cadence. Placeholders are an ordinal day of the month (e.g. \"3rd\") and a list of times of day."
              ))
            } else {
              descriptions.append(String(
                localized: "Monthly, \(combinedTimes)",
                bundle: Bundle.dataContainer,
                comment: "Combined reminder cadence. The placeholder is a list of times of day."
              ))
            }
          } else {
            // Different days of month, show individual descriptions
            descriptions.append(contentsOf: occurrencesForType.map { $0.cadenceDescription })
          }
        case .yearly:
          // For yearly, check if they have the same month and day
          if occurrencesForType.allSatisfy({ $0.monthOfYear == occurrencesForType.first?.monthOfYear && $0.dayOfYear == occurrencesForType.first?.dayOfYear }) {
            if let monthOfYear = occurrencesForType.first?.monthOfYear, let dayOfYear = occurrencesForType.first?.dayOfYear {
              let monthName = Calendar.current.monthSymbols[safe: monthOfYear - 1] ?? ""
              let ordinal = NumberFormatter.ordinal.string(for: dayOfYear) ?? "\(dayOfYear)"
              descriptions.append(String(
                localized: "Yearly on \(monthName) \(ordinal), \(combinedTimes)",
                bundle: Bundle.dataContainer,
                comment: "Combined reminder cadence. Placeholders are a month name, an ordinal day (e.g. \"3rd\"), and a list of times of day."
              ))
            } else {
              descriptions.append(String(
                localized: "Yearly, \(combinedTimes)",
                bundle: Bundle.dataContainer,
                comment: "Combined reminder cadence. The placeholder is a list of times of day."
              ))
            }
          } else {
            // Different months/days, show individual descriptions
            descriptions.append(contentsOf: occurrencesForType.map { $0.cadenceDescription })
          }
        }
      }
    }
    
    return ListFormatter.main.string(from: descriptions) ?? descriptions.joined(separator: ", ")
  }
}
