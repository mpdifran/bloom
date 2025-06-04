import Foundation
import SwiftData

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
    let descriptions = cadenceDescriptions
    
    if descriptions.isEmpty {
      return "No schedule set"
    } else if descriptions.count == 1 {
      return descriptions[0]
    } else {
      return descriptions.joined(separator: " • ")
    }
  }
}