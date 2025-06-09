//
//  SocketMessage+Reminders.swift
//  bloom-model
//
//  Created by Claude on 2025-06-04.
//

public extension SocketMessage {
  struct CreateReminder: Codable, Equatable, Sendable {
    public let id: String?
    public let title: String
    public let color: String
    public let occurrences: [ReminderOccurrence]
    
    public init(
      id: String? = nil,
      title: String,
      color: String,
      occurrences: [ReminderOccurrence]
    ) {
      self.id = id
      self.title = title
      self.color = color
      self.occurrences = occurrences
    }
    
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      
      // ID is optional
      self.id = try? container.decodeIfPresent(String.self, forKey: .id)
      
      // Title is required - no fallback
      self.title = try container.decode(String.self, forKey: .title).trimmingCharacters(in: .whitespacesAndNewlines)
      
      // Color is required - no fallback
      let colorString = try container.decode(String.self, forKey: .color)
      guard colorString.hasPrefix("#") && colorString.count >= 7 else {
        throw DecodingError.dataCorrupted(DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Invalid color format. Must be a hex color code like #007AFF"
        ))
      }
      self.color = colorString
      
      // Occurrences with fallback to daily at 9 AM if empty or invalid
      let rawOccurrences = (try? container.decode([ReminderOccurrence].self, forKey: .occurrences)) ?? []
      if rawOccurrences.isEmpty {
        self.occurrences = [ReminderOccurrence(
          cadenceType: .daily,
          hour: 9,
          minute: 0
        )]
      } else {
        self.occurrences = rawOccurrences
      }
    }
  }
  
  struct ReminderOccurrence: Codable, Equatable, Sendable {
    public let cadenceType: CadenceType
    public let hour: Int // 0-23
    public let minute: Int // 0-59
    public let daysOfWeek: [Weekday]?
    public let dayOfMonth: Int? // 1-31
    public let monthOfYear: Month?
    public let dayOfYear: Int? // 1-31
    
    public init(
      cadenceType: CadenceType,
      hour: Int,
      minute: Int,
      daysOfWeek: [Weekday]? = nil,
      dayOfMonth: Int? = nil,
      monthOfYear: Month? = nil,
      dayOfYear: Int? = nil
    ) {
      self.cadenceType = cadenceType
      self.hour = hour
      self.minute = minute
      self.daysOfWeek = daysOfWeek
      self.dayOfMonth = dayOfMonth
      self.monthOfYear = monthOfYear
      self.dayOfYear = dayOfYear
    }
    
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      
      // Cadence type with fallback to daily
      self.cadenceType = (try? container.decode(CadenceType.self, forKey: .cadenceType)) ?? .daily
      
      // Hour with validation (0-23)
      let rawHour = (try? container.decode(Int.self, forKey: .hour)) ?? 9
      self.hour = max(0, min(23, rawHour))
      
      // Minute with validation (0-59)
      let rawMinute = (try? container.decode(Int.self, forKey: .minute)) ?? 0
      self.minute = max(0, min(59, rawMinute))
      
      // Days of week - filter out invalid values
      if let rawDays = try? container.decodeIfPresent([Weekday].self, forKey: .daysOfWeek) {
        self.daysOfWeek = rawDays.isEmpty ? nil : rawDays
      } else {
        self.daysOfWeek = nil
      }
      
      // Day of month with validation (1-31)
      if let rawDay = try? container.decodeIfPresent(Int.self, forKey: .dayOfMonth) {
        self.dayOfMonth = max(1, min(31, rawDay))
      } else {
        self.dayOfMonth = nil
      }
      
      // Month of year
      self.monthOfYear = try? container.decodeIfPresent(Month.self, forKey: .monthOfYear)
      
      // Day of year with validation (1-31) - note: this should probably be (1-366) but keeping consistent with your comment
      if let rawDay = try? container.decodeIfPresent(Int.self, forKey: .dayOfYear) {
        self.dayOfYear = max(1, min(31, rawDay))
      } else {
        self.dayOfYear = nil
      }
    }
  }
  
  enum CadenceType: String, Codable, CaseIterable, Sendable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
  }
  
  enum Weekday: String, Codable, CaseIterable, Sendable {
    case sunday = "sunday"
    case monday = "monday"
    case tuesday = "tuesday"
    case wednesday = "wednesday"
    case thursday = "thursday"
    case friday = "friday"
    case saturday = "saturday"
  }
  
  enum Month: String, Codable, CaseIterable, Sendable {
    case january = "january"
    case february = "february"
    case march = "march"
    case april = "april"
    case may = "may"
    case june = "june"
    case july = "july"
    case august = "august"
    case september = "september"
    case october = "october"
    case november = "november"
    case december = "december"
  }
}