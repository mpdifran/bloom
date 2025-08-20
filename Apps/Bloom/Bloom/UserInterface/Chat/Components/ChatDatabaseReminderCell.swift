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
  
  @Query private var reminders: [Reminder]
  @State private var showingEditReminder = false
  
  init(reminderID: String) {
    self.reminderID = reminderID
    
    // Query for the specific reminder by ID
    let predicate = #Predicate<Reminder> { reminder in
      reminder.id == reminderID
    }
    
    _reminders = Query(
      filter: predicate,
      animation: .default
    )
  }
  
  var reminder: Reminder? {
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
          .onTapGesture {
            showingEditReminder = true
          }
        } else {
          // Reminder deleted - show grayed out state
          HStack {
            CompletionCheckmarkView(state: .unmetGoal, colorize: false)

            VStack(alignment: .leading) {
              Text("Reminder Deleted")
                .font(.title3)

              Text("No longer available")
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
          .chatCardContainer()
          .frame(width: 300)
          .padding(.horizontal)
        }
      }
      
      Spacer()
    }
    .sheet(isPresented: $showingEditReminder) {
      if let reminder {
        NavigationStack {
          CreateEditReminderView(reminder: reminder)
        }
      }
    }
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
