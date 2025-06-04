import Foundation
import SwiftData

public struct ReminderOccurrenceDTO: Sendable, Equatable, Identifiable {
  public let persistentModelID: PersistentIdentifier?
  public let id: String
  public let cadenceType: SchemaV18.ReminderCadenceType
  public let timeOfDay: TimeInterval
  public let daysOfWeek: [Int]?
  public let dayOfMonth: Int?
  public let monthOfYear: Int?
  public let dayOfYear: Int?
  
  public init(
    persistentModelID: PersistentIdentifier? = nil,
    id: String,
    cadenceType: SchemaV18.ReminderCadenceType,
    timeOfDay: TimeInterval,
    daysOfWeek: [Int]?,
    dayOfMonth: Int?,
    monthOfYear: Int?,
    dayOfYear: Int?
  ) {
    self.persistentModelID = persistentModelID
    self.id = id
    self.cadenceType = cadenceType
    self.timeOfDay = timeOfDay
    self.daysOfWeek = daysOfWeek
    self.dayOfMonth = dayOfMonth
    self.monthOfYear = monthOfYear
    self.dayOfYear = dayOfYear
  }
}

extension SchemaV18.ReminderOccurrence {
  public func asDTO() -> ReminderOccurrenceDTO {
    ReminderOccurrenceDTO(
      persistentModelID: persistentModelID,
      id: id,
      cadenceType: cadenceType,
      timeOfDay: timeOfDay,
      daysOfWeek: daysOfWeek,
      dayOfMonth: dayOfMonth,
      monthOfYear: monthOfYear,
      dayOfYear: dayOfYear
    )
  }
}