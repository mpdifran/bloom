import SwiftUI
import SwiftData
import BloomFoundation
import DataContainer
import SFSafeSymbols

struct RemindersEditListView: View {
  @Query(sort: \Reminder.createdDate) private var reminders: [Reminder]
  @State private var selectedReminder: Reminder?
  @State private var showingAddReminder = false
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Group {
        if reminders.isEmpty {
          emptyStateView
        } else {
          remindersList
        }
      }
      .navigationTitle("Reminders")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") {
            dismiss()
          }
          .bold()
        }

        ToolbarItem(placement: .primaryAction) {
          Button {
            showingAddReminder = true
          } label: {
            Image(systemSymbol: .plus)
          }
        }
      }
      .sheet(isPresented: $showingAddReminder) {
        CreateEditReminderView()
      }
    }
  }

  private var emptyStateView: some View {
    ContentUnavailableView {
      Label("No Reminders", systemSymbol: .bell)
    } description: {
      Text("Tap the + button to create your first reminder.")
    }
    .groupedBackground()
  }

  private var remindersList: some View {
    BloomScrollView {
      ForEach(reminders) { reminder in
        ReminderEditCell(reminder: reminder)
          .onTapGesture {
            selectedReminder = reminder
          }
      }
    }
    .sheet(item: $selectedReminder) { reminder in
      CreateEditReminderView(reminder: reminder)
    }
  }
}

#Preview {
  PreviewEnvironment {
    RemindersEditListView()
  }
}
