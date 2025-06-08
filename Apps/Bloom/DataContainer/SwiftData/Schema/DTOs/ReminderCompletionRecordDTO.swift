import Foundation
import SwiftData

public struct ReminderCompletionRecordDTO: Sendable, Equatable, Identifiable {
  public let persistentModelID: PersistentIdentifier
  public let id: String
  public let completedDate: Date
  public let occurrenceID: String?
  
  public init(
    persistentModelID: PersistentIdentifier,
    id: String,
    completedDate: Date,
    occurrenceID: String? = nil
  ) {
    self.persistentModelID = persistentModelID
    self.id = id
    self.completedDate = completedDate
    self.occurrenceID = occurrenceID
  }
}

extension ReminderCompletionRecord {
  public func asDTO() -> ReminderCompletionRecordDTO {
    ReminderCompletionRecordDTO(
      persistentModelID: persistentModelID,
      id: id,
      completedDate: completedDate,
      occurrenceID: occurrence?.id
    )
  }
}