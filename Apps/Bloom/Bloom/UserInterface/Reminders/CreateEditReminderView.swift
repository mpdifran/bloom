import SwiftUI
import SwiftData
import BloomFoundation
import DataContainer
import SFSafeSymbols
import AppUI

struct CreateEditReminderView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  
  @State private var title: String
  @State private var selectedColor: Color
  @State private var occurrences: [ReminderOccurrence]
  @State private var sideEffects: [ReminderSideEffect]
  @State private var showingAddOccurrence = false
  @State private var editingOccurrence: ReminderOccurrence?
  @State private var presentedSheet: AnyView?
  @State private var isSaving = false
  @State private var saveError: Error?
  @State private var isDeleting = false
  @State private var deleteError: Error?
  @State private var confirmationDetails: ConfirmationDialogDetails?

  private let existingReminder: Reminder?
  private let remindersManager = RemindersManager.shared
  
  init(reminder: Reminder? = nil) {
    self.existingReminder = reminder
    self._title = State(initialValue: reminder?.title ?? "")
    self._selectedColor = State(initialValue: reminder?.colorHex.isEmpty ?? true ? .accentColor : Color(hex: reminder!.colorHex) ?? .accentColor)
    self._occurrences = State(initialValue: reminder?.occurrences ?? [])
    self._sideEffects = State(initialValue: reminder?.sideEffects ?? [])
  }
  
  var body: some View {
    NavigationStack {
      BloomScrollView {
        titleSection
        occurrencesSection
        sideEffectsSection
      }
      .shelf {
        saveButton
      }
      .navigationTitle(existingReminder == nil ? "New Reminder" : "Edit Reminder")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        if existingReminder != nil {
          ToolbarItem(placement: .confirmationAction) {
            Button("Delete", role: .destructive) {
              confirmationDetails = ConfirmationDialogDetails(
                title: "Delete Reminder",
                message: "Are you sure you want to delete \"\(title.isEmpty ? "this reminder" : title)\"? This action cannot be undone.",
                buttons: [
                  ConfirmationDialogDetails.Button(title: "Delete", role: .destructive) {
                    deleteReminder()
                  }
                ]
              )
            }
            .tint(.mutedRed)
            .bold()
            .disabled(isDeleting || isSaving)
          }
        }
      }
      .animation(.default, value: occurrences)
      .animation(.default, value: sideEffects)
      .alert(error: $saveError)
      .alert(error: $deleteError)
      .confirmationDialog($confirmationDetails)
      .sheet($presentedSheet)
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
        ForEach(sortedOccurrences) { occurrence in
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
        .frame(minHeight: 40)
        .bold()
        .fontDesign(.rounded)
      }
      .cardContainer()
    }
  }
  
  private var sortedOccurrences: [ReminderOccurrence] {
    occurrences.sorted { first, second in
      // First sort by cadence type priority
      let cadenceOrder: [ReminderCadenceType] = [.daily, .weekly, .monthly, .yearly]
      let firstIndex = cadenceOrder.firstIndex(of: first.cadenceType) ?? cadenceOrder.count
      let secondIndex = cadenceOrder.firstIndex(of: second.cadenceType) ?? cadenceOrder.count
      
      if firstIndex != secondIndex {
        return firstIndex < secondIndex
      }
      
      // If same cadence type, sort by time of day
      return first.timeOfDay < second.timeOfDay
    }
  }

  var saveButton: some View {
    Button {
      saveReminder()
    } label: {
      Text("Save")
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
    .disabled(title.isEmpty || occurrences.isEmpty || isSaving)
  }

  private func saveReminder() {
    guard !isSaving else { return }
    
    isSaving = true
    let colorHex = selectedColor.toHex() ?? ""
    
    Task {
      do {
        if let existingReminder {
          // Update existing reminder
          _ = try await remindersManager.updateReminder(
            withID: existingReminder.id,
            title: title,
            colorHex: colorHex,
            occurrences: occurrences,
            sideEffects: sideEffects
          )
        } else {
          // Create new reminder
          _ = try await remindersManager.createReminder(
            title: title,
            colorHex: colorHex,
            occurrences: occurrences,
            sideEffects: sideEffects
          )
        }
        
        await MainActor.run {
          dismiss()
        }
      } catch {
        await MainActor.run {
          saveError = error
          isSaving = false
        }
      }
    }
  }
  
  private var sideEffectsSection: some View {
    VStack {
      SectionTitleView("Side Effects")
        .padding(.horizontal)

      VStack(alignment: .leading) {
        ForEach(sideEffects, id: \.id) { sideEffect in
          SideEffectCell(sideEffect: sideEffect)
            .contentShape(Rectangle())
            .onTapGesture {
              editSideEffect(sideEffect)
            }
            .contextMenu {
              Button("Delete", systemSymbol: .trash, role: .destructive) {
                sideEffects.removeAll { $0.id == sideEffect.id }
              }
              .tint(.red)
            }

          Divider()
        }

        Button {
          addSideEffect()
        } label: {
          Label("Add Side Effect", systemSymbol: .plus)
            .horizontallyCentered()
        }
        .frame(minHeight: 40)
        .bold()
        .fontDesign(.rounded)
      }
      .cardContainer()
    }
  }
  
  private func addSideEffect() {
    presentedSheet = SelectSideEffectTypeView { sideEffect in
      sideEffects.append(sideEffect)
    }.asAny
  }
  
  private func editSideEffect(_ sideEffect: ReminderSideEffect) {
    switch sideEffect.type {
    case .logFood:
      presentedSheet = ConfigureFoodSideEffectView(
        existingSideEffect: sideEffect
      ) { updatedSideEffect in
        if let index = sideEffects.firstIndex(where: { $0.id == sideEffect.id }) {
          sideEffects[index] = updatedSideEffect
        }
      }.asAny
    case .logWater:
      presentedSheet = ConfigureWaterSideEffectView(
        existingSideEffect: sideEffect
      ) { updatedSideEffect in
        if let index = sideEffects.firstIndex(where: { $0.id == sideEffect.id }) {
          sideEffects[index] = updatedSideEffect
        }
      }.asAny
    @unknown default:
      break
    }
  }
  
  private func deleteReminder() {
    guard !isDeleting, let existingReminder else { return }
    
    isDeleting = true
    
    Task {
      do {
        try await remindersManager.deleteReminder(withID: existingReminder.id)
        
        await MainActor.run {
          dismiss()
        }
      } catch {
        await MainActor.run {
          deleteError = error
          isDeleting = false
        }
      }
    }
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

#Preview("Multiple Occurrences") {
  PreviewEnvironment {
    CreateEditReminderView(
      reminder: Reminder(
        title: "Health routine",
        colorHex: "007AFF",
        occurrences: [
          // Intentionally unsorted to test sorting
          ReminderOccurrence(
            cadenceType: .monthly,
            timeOfDay: 8 * 3600,
            dayOfMonth: 1
          ),
          ReminderOccurrence(
            cadenceType: .daily,
            timeOfDay: 22 * 3600 // 10 PM
          ),
          ReminderOccurrence(
            cadenceType: .weekly,
            timeOfDay: 14 * 3600, // 2 PM
            daysOfWeek: [2, 4] // Monday, Wednesday
          ),
          ReminderOccurrence(
            cadenceType: .daily,
            timeOfDay: 9 * 3600 // 9 AM
          )
        ]
      )
    )
  }
}
