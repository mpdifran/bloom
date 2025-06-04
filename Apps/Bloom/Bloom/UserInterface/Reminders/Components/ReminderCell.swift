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
  let isCompleted: Bool

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
    .tint(reminder.color)
    .cardContainer()
    .frame(width: 280)
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
    guard let nextDate = reminder.nextNotificationDate else { return false }
    return nextDate < Date() && !isCompleted
  }
  
  private var overdueText: String {
    guard let lastMissed = reminder.lastMissedNotificationDate else {
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
    guard let nextDate = reminder.nextNotificationDate else {
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
