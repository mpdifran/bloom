import SwiftUI
import SwiftData
import BloomFoundation
import DataContainer
import SFSafeSymbols

struct CreateEditReminderView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  
  @State private var title: String
  @State private var selectedColor: Color
  @State private var occurrences: [ReminderOccurrence]
  @State private var showingAddOccurrence = false
  @State private var editingOccurrence: ReminderOccurrence?
  
  private let existingReminder: Reminder?
  
  init(reminder: Reminder? = nil) {
    self.existingReminder = reminder
    self._title = State(initialValue: reminder?.title ?? "")
    self._selectedColor = State(initialValue: reminder?.colorHex.isEmpty ?? true ? .accentColor : Color(hex: reminder!.colorHex) ?? .accentColor)
    self._occurrences = State(initialValue: reminder?.occurrences ?? [])
  }
  
  var body: some View {
    NavigationStack {
      BloomScrollView {
        titleSection
        occurrencesSection
      }
      .navigationTitle(existingReminder == nil ? "New Reminder" : "Edit Reminder")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveReminder()
          }
          .bold()
          .disabled(title.isEmpty || occurrences.isEmpty)
        }
      }
      .animation(.default, value: occurrences)
      .sheet(isPresented: $showingAddOccurrence) {
        EditReminderOccurrenceView(occurrence: nil) { newOccurrence in
          occurrences.append(newOccurrence)
        }
      }
      .sheet(item: $editingOccurrence) { occurrence in
        EditReminderOccurrenceView(
          occurrence: occurrence,
          onSave: { updatedOccurrence in
            if let index = occurrences.firstIndex(where: { $0.id == occurrence.id }) {
              occurrences[index] = updatedOccurrence
            }
          },
          onDelete: {
            occurrences.removeAll { $0.id == occurrence.id }
          }
        )
      }
    }
  }
  
  private var titleSection: some View {
    VStack {
      SectionTitleView("Details")
        .padding(.horizontal)

      VStack {
        LabeledContent("Title") {
          TextField("Reminder", text: $title)
            .bold()
            .fontDesign(.rounded)
            .multilineTextAlignment(.trailing)
            .submitLabel(.done)
        }

        Divider()

        LabeledContent("Color") {
          ColorPicker("Reminder Color", selection: $selectedColor)
            .labelsHidden()
        }
      }
      .cardContainer()
    }
  }
  
  private var occurrencesSection: some View {
    VStack {
      SectionTitleView("Notifications")
        .padding(.horizontal)

      VStack(alignment: .leading) {
        ForEach(occurrences) { occurrence in
          ReminderOccurrenceCell(occurrence: occurrence)
            .onTapGesture {
              editingOccurrence = occurrence
            }
            .contextMenu {
              Button("Delete", systemSymbol: .trash, role: .destructive) {
                occurrences.removeAll { $0.id == occurrence.id }
              }
              .tint(.red)
            }

          Divider()
        }

        Button {
          showingAddOccurrence = true
        } label: {
          Label("Add", systemSymbol: .plus)
            .horizontallyCentered()
        }
        .bold()
        .fontDesign(.rounded)
      }
      .cardContainer()
    }
  }
  
  private func saveReminder() {
    let colorHex = selectedColor.toHex() ?? ""
    
    if let existingReminder {
      // Update existing reminder
      existingReminder.title = title
      existingReminder.colorHex = colorHex
      existingReminder.occurrences = occurrences
      existingReminder.modifiedDate = Date()
    } else {
      // Create new reminder
      let newReminder = Reminder(
        title: title,
        colorHex: colorHex,
        occurrences: occurrences
      )
      modelContext.insert(newReminder)
    }
    
    dismiss()
  }
}

#Preview("New Reminder") {
  PreviewEnvironment {
    CreateEditReminderView()
  }
}

#Preview("Edit Reminder") {
  PreviewEnvironment {
    CreateEditReminderView(
      reminder: Reminder(
        title: "Take vitamins",
        colorHex: "51CF66",
        occurrences: [
          ReminderOccurrence(
            cadenceType: .daily,
            timeOfDay: 9 * 3600
          )
        ]
      )
    )
  }
}
