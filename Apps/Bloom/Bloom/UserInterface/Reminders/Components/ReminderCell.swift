//
//  ReminderCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-06-04.
//

import SwiftUI
import BloomFoundation
import DataContainer
import SwiftData

struct ReminderCell: View {
  let reminder: ReminderDTO
  let occurrence: ReminderOccurrenceDTO?
  let isCompleted: Bool

  @State private var completeToggle = false
  @State private var unCompleteToggle = false
  
  init(
    reminder: ReminderDTO,
    occurrence: ReminderOccurrenceDTO? = nil,
    isCompleted: Bool
  ) {
    self.reminder = reminder
    self.occurrence = occurrence
    self.isCompleted = isCompleted
  }
  
  /// The scheduled time for this specific occurrence (if available)
  private var scheduledTime: Date? {
    guard let occurrence = occurrence else { return nil }
    
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let hour = Int(occurrence.timeOfDay) / 3600
    let minute = (Int(occurrence.timeOfDay) % 3600) / 60
    
    return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today)
  }

  var body: some View {
    HStack {
      CompletionCheckmarkView(state: isCompleted ? .metGoal : .unmetGoal, colorize: true)

      VStack(alignment: .leading) {
        Text(reminder.title)
          .font(.title3)

        Text(subtitleText)
          .font(.subheadline)
          .foregroundStyle(isOverdue ? .red : .secondary)
      }
      .bold()
      .fontDesign(.rounded)
      .lineLimit(1)

      Spacer()
    }
    .sensoryFeedback(.success, trigger: completeToggle)
    .sensoryFeedback(.impact, trigger: unCompleteToggle)
    .tint(reminder.color)
    .cardContainer()
    .frame(width: 280)
    .onChange(of: isCompleted) { oldValue, newValue in
      if newValue {
        completeToggle.toggle()
      } else {
        unCompleteToggle.toggle()
      }
    }
  }
  
  private var subtitleText: String {
    guard !reminder.occurrences.isEmpty else { return "No schedule" }
    
    if isOverdue {
      return overdueText
    } else {
      return nextNotificationText
    }
  }
  
  private var isOverdue: Bool {
    if let occurrence = occurrence, let scheduledTime = scheduledTime {
      // Use specific occurrence time
      return scheduledTime < Date() && !isCompleted
    } else {
      // Fall back to reminder's general overdue status
      return reminder.isOverdueToday(completionRecords: reminder.completionRecords)
    }
  }
  
  private var overdueText: String {
    let targetTime: Date?
    
    if let occurrence = occurrence, let scheduledTime = scheduledTime {
      // Use specific occurrence time
      targetTime = scheduledTime
    } else {
      // Fall back to reminder's last missed date
      targetTime = reminder.lastMissedNotificationDate
    }
    
    guard let lastMissed = targetTime else {
      return "Overdue"
    }
    
    let formatter = DateFormatter()
    let calendar = Calendar.current
    
    if calendar.isDateInToday(lastMissed) {
      formatter.dateFormat = "h:mm a"
      return "Overdue from \(formatter.string(from: lastMissed))"
    } else if calendar.isDateInYesterday(lastMissed) {
      formatter.dateFormat = "h:mm a"
      return "Overdue from yesterday at \(formatter.string(from: lastMissed))"
    } else {
      formatter.dateFormat = "MMM d 'at' h:mm a"
      return "Overdue from \(formatter.string(from: lastMissed))"
    }
  }
  
  private var nextNotificationText: String {
    let targetTime: Date?
    
    if let occurrence = occurrence, let scheduledTime = scheduledTime {
      // Use specific occurrence time
      targetTime = scheduledTime
    } else {
      // Fall back to reminder's next notification date
      targetTime = reminder.nextNotificationDate
    }
    
    guard let nextDate = targetTime else {
      return "No upcoming notifications"
    }
    
    let formatter = DateFormatter()
    let calendar = Calendar.current
    
    if calendar.isDateInToday(nextDate) {
      formatter.dateFormat = "h:mm a"
      return "Today at \(formatter.string(from: nextDate))"
    } else if calendar.isDateInTomorrow(nextDate) {
      formatter.dateFormat = "h:mm a"
      return "Tomorrow at \(formatter.string(from: nextDate))"
    } else {
      formatter.dateFormat = "MMM d 'at' h:mm a"
      return formatter.string(from: nextDate)
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ReminderCell(
        reminder: Reminder.Preview.dailyVitamins.asDTO(),
        isCompleted: false
      )
      
      ReminderCell(
        reminder: Reminder.Preview.weeklyWaterPlants.asDTO(),
        isCompleted: true
      )
      
      ReminderCell(
        reminder: Reminder.Preview.monthlyPayRent.asDTO(),
        isCompleted: false
      )
    }
  }
}
