import Foundation
import SwiftData

public struct ReminderCompletionRecordDTO: Sendable, Equatable, Identifiable {
  public let persistentModelID: PersistentIdentifier
  public let id: String
  public let completedDate: Date
  
  public init(
    persistentModelID: PersistentIdentifier,
    id: String,
    completedDate: Date
  ) {
    self.persistentModelID = persistentModelID
    self.id = id
    self.completedDate = completedDate
  }
}

extension SchemaV18.ReminderCompletionRecord {
  public func asDTO() -> ReminderCompletionRecordDTO {
    ReminderCompletionRecordDTO(
      persistentModelID: persistentModelID,
      id: id,
      completedDate: completedDate
    )
  }
}