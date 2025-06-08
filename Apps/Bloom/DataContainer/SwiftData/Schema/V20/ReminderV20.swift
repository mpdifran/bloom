import Foundation
import SwiftData

extension SchemaV20 {
  @Model
  public final class Reminder: Hashable, Identifiable {
    public var id = UUID().uuidString
    public var createdDate: Date = Date()
    public var modifiedDate: Date = Date()
    
    public var title: String = ""
    public var colorHex: String = ""
    
    @Relationship(deleteRule: .cascade, inverse: \ReminderOccurrence.reminder)
    public var occurrences: [ReminderOccurrence]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \ReminderCompletionRecord.reminder)
    public var completionRecords: [ReminderCompletionRecord]? = []
    
    public init(
      id: String = UUID().uuidString,
      title: String = "",
      colorHex: String = "",
      occurrences: [ReminderOccurrence]? = [],
      completionRecords: [ReminderCompletionRecord]? = []
    ) {
      self.id = id
      self.title = title
      self.colorHex = colorHex
      self.occurrences = occurrences
      self.completionRecords = completionRecords
    }
  }
}