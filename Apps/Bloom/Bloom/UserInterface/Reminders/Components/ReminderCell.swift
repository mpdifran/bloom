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
import SFSafeSymbols

struct ReminderCell: View {
  let reminder: ReminderDTO
  let occurrence: ReminderOccurrenceDTO?
  let scheduledTime: Date
  let isCompleted: Bool

  @State private var completeToggle = false
  @State private var unCompleteToggle = false
  
  init(
    reminder: ReminderDTO,
    occurrence: ReminderOccurrenceDTO? = nil,
    scheduledTime: Date,
    isCompleted: Bool
  ) {
    self.reminder = reminder
    self.occurrence = occurrence
    self.scheduledTime = scheduledTime
    self.isCompleted = isCompleted
  }
  
  var body: some View {
    TimelineView(.everyMinute) { _ in
      HStack {
        CompletionCheckmarkView(state: isCompleted ? .metGoal : .unmetGoal, colorize: true)

        VStack(alignment: .leading) {
          HStack {
            Text(reminder.title)
              .font(.title3)
            
            if let triggerType = reminder.triggerType {
              Image(systemSymbol: SFSymbol(rawValue: triggerType.systemImageName))
                .font(.caption)
                .foregroundColor(.accentColor)
                .help(triggerType.description)
            }
            
            Spacer()
          }

          Text(subtitleText())
            .font(.subheadline)
            .foregroundStyle(subtitleTextColor())
        }
        .bold()
        .fontDesign(.rounded)
        .lineLimit(1)
      }
      .sensoryFeedback(.success, trigger: completeToggle)
      .sensoryFeedback(.impact, trigger: unCompleteToggle)
      .tint(reminder.color)
      .cardContainer()
      .frame(width: 280)
      .onChange(of: isCompleted) { _, newValue in
        if newValue {
          completeToggle.toggle()
        } else {
          unCompleteToggle.toggle()
        }
      }
    }
  }
  
  private func subtitleText() -> String {
    guard !reminder.occurrences.isEmpty else { return "No schedule" }
    
    if isDueNow {
      return "Due now"
    } else if isOverdue {
      return overdueText
    } else {
      return nextNotificationText
    }
  }
  
  private func subtitleTextColor() -> Color {
    if isOverdue {
      return .red
    } else {
      return .secondary
    }
  }
  
  private var isDueNow: Bool {
    // Only check if not completed
    guard !isCompleted else { return false }

    if let _ = occurrence {
      // Check if we're within the "due now" window (scheduled time to 5 minutes after)
      let now = Date()
      let fiveMinutesAfter = scheduledTime.addingTimeInterval(5 * 60)
      return scheduledTime <= now && now <= fiveMinutesAfter
    }
    return false
  }
  
  private var isOverdue: Bool {
    if let _ = occurrence {
      // Use specific occurrence time
      // It's overdue if it's past the 5-minute "due now" window
      let fiveMinutesAfter = scheduledTime.addingTimeInterval(5 * 60)
      return fiveMinutesAfter < Date() && !isCompleted
    } else {
      // Fall back to reminder's general overdue status
      return reminder.isOverdueToday(completionRecords: reminder.completionRecords)
    }
  }
  
  private var overdueText: String {
    let targetTime: Date?
    
    if let _ = occurrence {
      // Use specific occurrence time
      targetTime = scheduledTime
    } else {
      // Fall back to reminder's last missed date
      targetTime = reminder.lastMissedNotificationDate
    }
    
    guard let lastMissed = targetTime else {
      return "Overdue"
    }
    
    let calendar = Calendar.current

    // Locale-aware: fixed "h:mm a"/"MMM d" patterns forced 12-hour AM/PM and month-first order
    // on locales that use neither.
    if calendar.isDateInToday(lastMissed) {
      return "Overdue \(DateFormatter.justTimeShort.string(from: lastMissed))"
    } else if calendar.isDateInYesterday(lastMissed) {
      return "Overdue yesterday at \(DateFormatter.justTimeShort.string(from: lastMissed))"
    } else {
      return "Overdue \(lastMissed.formatted(.dateTime.month().day().hour().minute()))"
    }
  }
  
  private var nextNotificationText: String {
    let targetTime: Date?
    
    if let _ = occurrence {
      // Use specific occurrence time
      targetTime = scheduledTime
    } else {
      // Fall back to reminder's next notification date
      targetTime = reminder.nextNotificationDate
    }
    
    guard let nextDate = targetTime else {
      return "No upcoming notifications"
    }
    
    let calendar = Calendar.current

    // Locale-aware: fixed "h:mm a"/"MMM d" patterns forced 12-hour AM/PM and month-first order
    // on locales that use neither.
    if calendar.isDateInToday(nextDate) {
      return "Today at \(DateFormatter.justTimeShort.string(from: nextDate))"
    } else if calendar.isDateInTomorrow(nextDate) {
      return "Tomorrow at \(DateFormatter.justTimeShort.string(from: nextDate))"
    } else {
      return nextDate.formatted(.dateTime.month().day().hour().minute())
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ReminderCell(
        reminder: Reminder.Preview.dailyVitamins.asDTO(),
        scheduledTime: .now,
        isCompleted: false
      )
      
      ReminderCell(
        reminder: Reminder.Preview.weeklyWaterPlants.asDTO(),
        scheduledTime: .now,
        isCompleted: true
      )
      
      ReminderCell(
        reminder: Reminder.Preview.monthlyPayRent.asDTO(),
        scheduledTime: .now,
        isCompleted: false
      )
    }
  }
}
