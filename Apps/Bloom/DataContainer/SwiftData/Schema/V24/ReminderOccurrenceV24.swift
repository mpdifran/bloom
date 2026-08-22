import Foundation
import SwiftData

extension SchemaV24 {
  @Model
  public final class ReminderOccurrence: Hashable, Identifiable {
    public var id = UUID().uuidString
    
    public var cadenceType = ReminderCadenceType.daily
    public var timeOfDay: TimeInterval = 0
    
    public var daysOfWeek: [Int]? = []
    
    public var dayOfMonth: Int? = nil
    
    public var monthOfYear: Int? = nil
    public var dayOfYear: Int? = nil
    
    public var reminder: Reminder? = nil
    
    public init(
      cadenceType: ReminderCadenceType = .daily,
      timeOfDay: TimeInterval = 0,
      daysOfWeek: [Int]? = [],
      dayOfMonth: Int? = nil,
      monthOfYear: Int? = nil,
      dayOfYear: Int? = nil
    ) {
      self.cadenceType = cadenceType
      self.timeOfDay = timeOfDay
      self.daysOfWeek = daysOfWeek
      self.dayOfMonth = dayOfMonth
      self.monthOfYear = monthOfYear
      self.dayOfYear = dayOfYear
    }
  }
  
  public enum ReminderCadenceType: String, Codable, CaseIterable, Sendable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    
    public var displayName: String {
      switch self {
      case .daily:
        return String(localized: "Daily", bundle: Bundle.dataContainer, comment: "Display name for a reminder cadence type")
      case .weekly:
        return String(localized: "Weekly", bundle: Bundle.dataContainer, comment: "Display name for a reminder cadence type")
      case .monthly:
        return String(localized: "Monthly", bundle: Bundle.dataContainer, comment: "Display name for a reminder cadence type")
      case .yearly:
        return String(localized: "Yearly", bundle: Bundle.dataContainer, comment: "Display name for a reminder cadence type")
      }
    }
  }
}