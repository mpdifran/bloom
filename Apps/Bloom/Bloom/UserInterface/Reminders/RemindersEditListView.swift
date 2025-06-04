import SwiftUI
import SwiftData
import BloomFoundation
import DataContainer
import SFSafeSymbols

struct RemindersEditListView: View {
  @Query(sort: \Reminder.createdDate) private var reminders: [Reminder]
  @State private var selectedReminder: Reminder?
  @State private var showingAddReminder = false
  @State private var deleteError: Error?
  @Environment(\.dismiss) private var dismiss
  
  private let remindersManager = RemindersManager.shared

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
          .contextMenu {
            Button(role: .destructive) {
              deleteReminder(reminder)
            } label: {
              Label("Delete", systemSymbol: .trash)
            }
          }
      }
    }
    .sheet(item: $selectedReminder) { reminder in
      CreateEditReminderView(reminder: reminder)
    }
    .alert(error: $deleteError)
  }
  
  private func deleteReminder(_ reminder: Reminder) {
    Task {
      do {
        try await remindersManager.deleteReminder(withID: reminder.id)
      } catch {
        await MainActor.run {
          deleteError = error
        }
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    RemindersEditListView()
  }
}
