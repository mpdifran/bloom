import Foundation
import SwiftData

extension SchemaV23 {
  @Model
  public final class ReminderCompletionRecord: Hashable, Identifiable {
    public var id = UUID().uuidString
    public var completedDate: Date = Date()
    public var sideEffectResults: Data? = nil
    
    public var reminder: Reminder? = nil
    public var occurrence: ReminderOccurrence? = nil
    
    public init(
      reminder: Reminder? = nil,
      occurrence: ReminderOccurrence? = nil,
      completedDate: Date = Date()
    ) {
      self.reminder = reminder
      self.occurrence = occurrence
      self.completedDate = completedDate
    }
  }
}