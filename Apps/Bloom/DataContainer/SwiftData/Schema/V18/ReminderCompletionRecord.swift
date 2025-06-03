import Foundation
import SwiftData

extension SchemaV18 {
  @Model
  public final class ReminderCompletionRecord: Hashable, Identifiable, @unchecked Sendable {
    public var id = UUID().uuidString
    public var completedDate: Date = Date()
    
    public var reminder: Reminder? = nil
    
    public init(
      reminder: Reminder? = nil,
      completedDate: Date = Date()
    ) {
      self.reminder = reminder
      self.completedDate = completedDate
    }
  }
}
