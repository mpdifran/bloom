import Foundation
import SwiftData

public struct ReminderDTO: Sendable, Equatable, Identifiable {
  public let persistentModelID: PersistentIdentifier?
  public let id: String
  public let createdDate: Date
  public let modifiedDate: Date
  public let title: String
  public let colorHex: String
  public let occurrences: [ReminderOccurrenceDTO]
  public let completionRecords: [ReminderCompletionRecordDTO]
  public let sideEffects: [ReminderSideEffectDTO]
  
  public init(
    persistentModelID: PersistentIdentifier? = nil,
    id: String,
    createdDate: Date,
    modifiedDate: Date,
    title: String,
    colorHex: String,
    occurrences: [ReminderOccurrenceDTO],
    completionRecords: [ReminderCompletionRecordDTO],
    sideEffects: [ReminderSideEffectDTO] = []
  ) {
    self.persistentModelID = persistentModelID
    self.id = id
    self.createdDate = createdDate
    self.modifiedDate = modifiedDate
    self.title = title
    self.colorHex = colorHex
    self.occurrences = occurrences
    self.completionRecords = completionRecords
    self.sideEffects = sideEffects
  }
}

extension Reminder {
  public func asDTO() -> ReminderDTO {
    ReminderDTO(
      persistentModelID: persistentModelID,
      id: id,
      createdDate: createdDate,
      modifiedDate: modifiedDate,
      title: title,
      colorHex: colorHex,
      occurrences: occurrences?.map { $0.asDTO() } ?? [],
      completionRecords: completionRecords?.map { $0.asDTO() } ?? [],
      sideEffects: sideEffects?.map { $0.asDTO() } ?? []
    )
  }
}
