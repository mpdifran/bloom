import Foundation
import SwiftData

extension SchemaV24 {
  @Model
  public final class Reminder: Hashable, Identifiable {
    public var id = UUID().uuidString
    public var createdDate: Date = Date()
    public var modifiedDate: Date = Date()
    
    public var title: String = ""
    public var colorHex: String = ""
    
    // New property for V24: trigger type for automatic completion
    public var triggerType: String? = nil
    
    @Relationship(deleteRule: .cascade, inverse: \ReminderOccurrence.reminder)
    public var occurrences: [ReminderOccurrence]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \ReminderCompletionRecord.reminder)
    public var completionRecords: [ReminderCompletionRecord]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \ReminderSideEffect.reminder)
    public var sideEffects: [ReminderSideEffect]? = []
    
    public init(
      id: String = UUID().uuidString,
      title: String = "",
      colorHex: String = "",
      triggerType: String? = nil,
      occurrences: [ReminderOccurrence]? = [],
      completionRecords: [ReminderCompletionRecord]? = [],
      sideEffects: [ReminderSideEffect]? = []
    ) {
      self.id = id
      self.title = title
      self.colorHex = colorHex
      self.triggerType = triggerType
      self.occurrences = occurrences
      self.completionRecords = completionRecords
      self.sideEffects = sideEffects
    }
  }
}