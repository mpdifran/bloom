import Foundation
import SwiftData

extension ReminderOccurrence {
  @Transient
  public var time: Date {
    get {
      let calendar = Calendar.current
      let startOfDay = calendar.startOfDay(for: Date())
      return startOfDay.addingTimeInterval(timeOfDay)
    }
    set {
      let calendar = Calendar.current
      let components = calendar.dateComponents([.hour, .minute], from: newValue)
      let hours = components.hour ?? 0
      let minutes = components.minute ?? 0
      timeOfDay = TimeInterval(hours * 3600 + minutes * 60)
    }
  }
  
  public func nextOccurrence(after date: Date) -> Date? {
    let calendar = Calendar.current
    
    switch cadenceType {
    case .daily:
      return nextDailyOccurrence(after: date, calendar: calendar)
    case .weekly:
      return nextWeeklyOccurrence(after: date, calendar: calendar)
    case .monthly:
      return nextMonthlyOccurrence(after: date, calendar: calendar)
    case .yearly:
      return nextYearlyOccurrence(after: date, calendar: calendar)
    }
  }
  
  private func nextDailyOccurrence(after date: Date, calendar: Calendar) -> Date? {
    let startOfDay = calendar.startOfDay(for: date)
    var nextDate = startOfDay.addingTimeInterval(timeOfDay)
    
    if nextDate <= date {
      nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
    }
    
    return nextDate
  }
  
  private func nextWeeklyOccurrence(after date: Date, calendar: Calendar) -> Date? {
    guard let daysOfWeek = daysOfWeek, !daysOfWeek.isEmpty else {
      return nil
    }
    
    let startOfDay = calendar.startOfDay(for: date)
    let todayWeekday = calendar.component(.weekday, from: date)
    let currentTime = date.timeIntervalSince(startOfDay)
    
    let sortedDays = daysOfWeek.sorted()
    
    for dayOffset in 0..<7 {
      let targetWeekday = ((todayWeekday - 1 + dayOffset) % 7) + 1
      
      if sortedDays.contains(targetWeekday) {
        let daysToAdd = dayOffset
        var nextDate = calendar.date(byAdding: .day, value: daysToAdd, to: startOfDay)!
        nextDate = nextDate.addingTimeInterval(timeOfDay)
        
        if nextDate > date || (dayOffset == 0 && timeOfDay > currentTime) {
          return nextDate
        }
      }
    }
    
    if let firstDay = sortedDays.first {
      let daysUntilFirst = (firstDay - todayWeekday + 7) % 7
      let weeksToAdd = daysUntilFirst == 0 ? 1 : 0
      var nextDate = calendar.date(byAdding: .day, value: daysUntilFirst + (weeksToAdd * 7), to: startOfDay)!
      nextDate = nextDate.addingTimeInterval(timeOfDay)
      return nextDate
    }
    
    return nil
  }
  
  private func nextMonthlyOccurrence(after date: Date, calendar: Calendar) -> Date? {
    guard let dayOfMonth = dayOfMonth else {
      return nil
    }
    
    var components = calendar.dateComponents([.year, .month], from: date)
    components.day = dayOfMonth
    components.hour = Int(timeOfDay / 3600)
    components.minute = Int((timeOfDay.truncatingRemainder(dividingBy: 3600)) / 60)
    
    if let nextDate = calendar.date(from: components), nextDate > date {
      return nextDate
    }
    
    components.month! += 1
    
    while components.month! <= components.month! + 12 {
      if let nextDate = calendar.date(from: components) {
        return nextDate
      }
      components.month! += 1
    }
    
    return nil
  }
  
  private func nextYearlyOccurrence(after date: Date, calendar: Calendar) -> Date? {
    guard let monthOfYear = monthOfYear, let dayOfYear = dayOfYear else {
      return nil
    }
    
    var components = calendar.dateComponents([.year], from: date)
    components.month = monthOfYear
    components.day = dayOfYear
    components.hour = Int(timeOfDay / 3600)
    components.minute = Int((timeOfDay.truncatingRemainder(dividingBy: 3600)) / 60)
    
    if let nextDate = calendar.date(from: components), nextDate > date {
      return nextDate
    }
    
    components.year! += 1
    return calendar.date(from: components)
  }
  
  public func repeatingNotificationDateComponents() -> DateComponents {
    var components = DateComponents()
    
    // Set time components
    let hours = Int(timeOfDay / 3600)
    let minutes = Int((timeOfDay.truncatingRemainder(dividingBy: 3600)) / 60)
    components.hour = hours
    components.minute = minutes
    
    switch cadenceType {
    case .daily:
      // For daily, only hour and minute are needed
      // This will repeat every day at the specified time
      break
      
    case .weekly:
      // For weekly, we need a specific weekday
      // Note: For multiple weekdays, each needs its own notification
      if let firstDay = daysOfWeek?.first {
        components.weekday = firstDay
      }
      
    case .monthly:
      // For monthly, we need the day of month
      components.day = dayOfMonth
      
    case .yearly:
      // For yearly, we need month and day
      components.month = monthOfYear
      components.day = dayOfYear
    }
    
    return components
  }
  
  public func allRepeatingNotificationDateComponents() -> [(identifier: String, components: DateComponents)] {
    if cadenceType == .weekly, let days = daysOfWeek, !days.isEmpty {
      // For weekly with multiple days, create separate components for each day
      return days.enumerated().map { index, weekday in
        var components = DateComponents()
        components.hour = Int(timeOfDay / 3600)
        components.minute = Int((timeOfDay.truncatingRemainder(dividingBy: 3600)) / 60)
        components.weekday = weekday
        return (identifier: "\(id)-\(index)", components: components)
      }
    } else {
      // For all other cases, return single DateComponents
      return [(identifier: id, components: repeatingNotificationDateComponents())]
    }
  }
  
  public var cadenceDescription: String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    
    let timeString = formatter.string(from: time)
    
    switch cadenceType {
    case .daily:
      return "Every day at \(timeString)"
      
    case .weekly:
      guard let days = daysOfWeek, !days.isEmpty else {
        return "Weekly at \(timeString)"
      }

      let sortedDays = days.sorted()
      
      // Check if all days are weekdays (Monday-Friday, which are 2-6 in iOS)
      let weekdays = Set([2, 3, 4, 5, 6])
      if Set(sortedDays) == weekdays {
        return "Weekdays at \(timeString)"
      }
      
      // Check if all days are weekends (Saturday-Sunday, which are 7 and 1 in iOS)
      let weekends = Set([1, 7])
      if Set(sortedDays) == weekends {
        return "Weekends at \(timeString)"
      }
      
      let dayNames = sortedDays.compactMap { Calendar.current.weekdaySymbols[safe: $0 - 1] }
      
      if dayNames.count == 1 {
        return "Every \(dayNames[0]) at \(timeString)"
      } else if dayNames.count == 2 {
        return "Every \(dayNames[0]) and \(dayNames[1]) at \(timeString)"
      } else {
        let allButLast = dayNames.dropLast()
        let commaSeparated = allButLast.joined(separator: ", ")
        return "Every \(commaSeparated), and \(dayNames.last!) at \(timeString)"
      }
      
    case .monthly:
      guard let day = dayOfMonth else {
        return "Monthly at \(timeString)"
      }
      
      let ordinal = NumberFormatter.ordinal.string(from: NSNumber(value: day)) ?? "\(day)"
      return "Every month on the \(ordinal) at \(timeString)"
      
    case .yearly:
      guard let month = monthOfYear, let day = dayOfYear else {
        return "Yearly at \(timeString)"
      }
      
      let monthName = Calendar.current.monthSymbols[safe: month - 1] ?? ""
      let ordinal = NumberFormatter.ordinal.string(from: NSNumber(value: day)) ?? "\(day)"
      return "Every year on \(monthName) \(ordinal) at \(timeString)"
    }
  }
}

private extension Collection {
  subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}
