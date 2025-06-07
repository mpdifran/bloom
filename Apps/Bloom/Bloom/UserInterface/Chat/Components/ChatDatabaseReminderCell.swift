//
//  ChatDatabaseReminderCell.swift
//  Bloom
//
//  Created by Assistant on 2025-06-06.
//

import SwiftUI
import BloomFoundation
import DataContainer
import SwiftData

struct ChatDatabaseReminderCell: View {
  let reminderID: String
  
  @Query private var reminders: [SchemaV18.Reminder]
  
  init(reminderID: String) {
    self.reminderID = reminderID
    
    // Query for the specific reminder by ID
    let predicate = #Predicate<SchemaV18.Reminder> { reminder in
      reminder.id == reminderID
    }
    
    _reminders = Query(
      filter: predicate,
      animation: .default
    )
  }
  
  var reminder: SchemaV18.Reminder? {
    reminders.first
  }
  
  var isDeleted: Bool {
    reminder == nil
  }
  
  var body: some View {
    HStack {
      HStack {
        if let reminder {
          // Reminder exists - show normal state
          ChatReminderCell(
            reminder: reminder.asDTO(),
            occurrence: reminder.occurrences?.first?.asDTO(),
            isCompleted: false
          )
        } else {
          // Reminder deleted - show grayed out state
          HStack {
            CompletionCheckmarkView(state: .unmetGoal, colorize: false)

            VStack(alignment: .leading) {
              Text("Reminder no longer available")
                .font(.title3)

              Text("This reminder has been deleted")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            .bold()
            .fontDesign(.rounded)
            .lineLimit(1)

            Spacer()
          }
          .foregroundStyle(.secondary)
          .tint(.gray)
          .cardContainer()
          .frame(width: 280)
        }
      }
      
      Spacer()
    }
    .padding(.leading)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      // Valid reminder
      ChatDatabaseReminderCell(reminderID: "valid-reminder-id")
      
      // Deleted reminder (assuming this ID doesn't exist)
      ChatDatabaseReminderCell(reminderID: "deleted-reminder-id")
    }
  }
}