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
}