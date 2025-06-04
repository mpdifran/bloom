import Foundation
import SwiftData
import BloomFoundation

typealias ReminderCadenceType = SchemaV18.ReminderCadenceType

extension Reminder {
  public func isCompleted(for date: Date) -> Bool {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
    
    return completionRecords?.contains { record in
      record.completedDate >= startOfDay && record.completedDate < endOfDay
    } ?? false
  }
  
  public func markCompleted(for date: Date) {
    guard !isCompleted(for: date) else { return }
    
    let record = ReminderCompletionRecord(reminder: self, completedDate: date)
    completionRecords?.append(record)
    modifiedDate = Date()
  }
  
  public func markIncomplete(for date: Date) {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
    
    completionRecords?.removeAll { record in
      record.completedDate >= startOfDay && record.completedDate < endOfDay
    }
    modifiedDate = Date()
  }
  
  public var cadenceDescriptions: [String] {
    occurrences?.map { $0.cadenceDescription } ?? []
  }
  
  public var combinedCadenceDescription: String {
    guard let occurrences = occurrences, !occurrences.isEmpty else {
      return "No schedule set"
    }
    
    // Group occurrences by cadence type
    let groupedOccurrences = Dictionary(grouping: occurrences) { $0.cadenceType }
    
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
          descriptions.append("Daily, \(combinedTimes)")
        case .weekly:
          // For weekly, we need to check if they have the same days
          let allDaysOfWeek = occurrencesForType.compactMap { $0.daysOfWeek }.flatMap { $0 }
          let uniqueDays = Set(allDaysOfWeek)
          
          if occurrencesForType.allSatisfy({ $0.daysOfWeek == occurrencesForType.first?.daysOfWeek }) {
            // All occurrences have the same days of week
            let dayNames = uniqueDays.sorted().compactMap { Calendar.current.weekdaySymbols[safe: $0 - 1] }
            if dayNames.count == 7 {
              descriptions.append("Daily, \(combinedTimes)")
            } else if dayNames.count == 5 && Set([2, 3, 4, 5, 6]).isSubset(of: uniqueDays) {
              descriptions.append("Weekdays, \(combinedTimes)")
            } else if dayNames.count == 2 && Set([1, 7]).isSubset(of: uniqueDays) {
              descriptions.append("Weekends, \(combinedTimes)")
            } else {
              let formattedDays = ListFormatter.main.string(from: dayNames) ?? dayNames.joined(separator: ", ")
              descriptions.append("Every \(formattedDays), \(combinedTimes)")
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
              descriptions.append("Monthly on the \(ordinal), \(combinedTimes)")
            } else {
              descriptions.append("Monthly, \(combinedTimes)")
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
              descriptions.append("Yearly on \(monthName) \(ordinal), \(combinedTimes)")
            } else {
              descriptions.append("Yearly, \(combinedTimes)")
            }
          } else {
            // Different dates, show individual descriptions
            descriptions.append(contentsOf: occurrencesForType.map { $0.cadenceDescription })
          }
        }
      }
    }
    
    if descriptions.isEmpty {
      return "No schedule set"
    } else if descriptions.count == 1 {
      return descriptions[0]
    } else {
      return descriptions.joined(separator: " • ")
    }
  }
}
