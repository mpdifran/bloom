import SwiftUI
import BloomFoundation
import DataContainer
import SFSafeSymbols

struct EditReminderOccurrenceView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var cadenceType: ReminderCadenceType
  @State private var selectedTime: Date
  @State private var selectedWeekdays: Set<Int>
  @State private var selectedDayOfMonth: Int
  @State private var selectedMonth: Int
  @State private var selectedDayOfYear: Int

  private let existingOccurrence: ReminderOccurrence?
  private let onSave: (ReminderOccurrence) -> Void
  private let onDelete: (() -> Void)?

  init(
    occurrence: ReminderOccurrence?,
    onSave: @escaping (ReminderOccurrence) -> Void,
    onDelete: (() -> Void)? = nil
  ) {
    self.existingOccurrence = occurrence
    self.onSave = onSave
    self.onDelete = onDelete

    // Initialize state
    let calendar = Calendar.current
    let now = Date()

    self._cadenceType = State(initialValue: occurrence?.cadenceType ?? .daily)

    // Convert timeOfDay to Date for time picker
    let timeOfDay = occurrence?.timeOfDay ?? (9 * 3600) // Default to 9 AM
    let startOfDay = calendar.startOfDay(for: now)
    self._selectedTime = State(initialValue: startOfDay.addingTimeInterval(timeOfDay))

    // Weekly
    self._selectedWeekdays = State(initialValue: Set(occurrence?.daysOfWeek ?? []))

    // Monthly
    self._selectedDayOfMonth = State(initialValue: occurrence?.dayOfMonth ?? calendar.component(.day, from: now))

    // Yearly
    self._selectedMonth = State(initialValue: occurrence?.monthOfYear ?? calendar.component(.month, from: now))
    self._selectedDayOfYear = State(initialValue: occurrence?.dayOfYear ?? calendar.component(.day, from: now))
  }

  var body: some View {
    CardView {
      LargeTitleActionCard(existingOccurrence == nil ? "New Notification" : "Edit Notification") {
        frequencySection
        saveSection
          .padding(.top)
      } leading: {
        Button {
          dismiss()
        } label: {
          Text("Cancel")
        }
      } trailing: {
        deleteButton
      }
    }
    .animation(.default, value: cadenceType)
  }
}

private extension EditReminderOccurrenceView {

  var frequencySection: some View {
    VStack {
      LabeledContent("Repeats") {
        Picker("Repeat", selection: $cadenceType) {
          ForEach(ReminderCadenceType.allCases, id: \.self) { type in
            Text(type.displayName).tag(type)
          }
        }
        .pickerStyle(.menu)
      }

      switch cadenceType {
      case .weekly:
        Divider()
        weeklyContent
      case .monthly:
        Divider()
        monthlyContent
      case .yearly:
        Divider()
        yearlyContent
      default:
        EmptyView()
      }

      Divider()

      DatePicker(
        "Time",
        selection: $selectedTime,
        displayedComponents: .hourAndMinute
      )
    }
    .cardContainer()
  }

  var weeklyContent: some View {
    HStack {
      ForEach(1...7, id: \.self) { weekday in
        if weekday > 1 {
          Spacer()
        }

        ReminderOccurrenceWeekdayIndicator(
          title: Calendar.current.veryShortWeekdaySymbols[weekday - 1],
          isSelected: selectedWeekdays.contains(weekday)
        )
        .onTapGesture {
          selectedWeekdays.toggleMembership(weekday)
        }
      }
    }
    .sensoryFeedback(.selection, trigger: selectedWeekdays)
  }
  
  var monthlyContent: some View {
    LabeledContent("Day") {
      Picker("Day", selection: $selectedDayOfMonth) {
        ForEach(1...31, id: \.self) { day in
          Text("\(day)")
            .tag(day)
        }
      }
      .pickerStyle(.menu)
    }
  }

  @ViewBuilder
  var yearlyContent: some View {
    LabeledContent("Month") {
      Picker("Month", selection: $selectedMonth) {
        ForEach(1...12, id: \.self) { month in
          Text(Calendar.current.monthSymbols[month - 1]).tag(month)
        }
      }
    }

    Divider()

    LabeledContent("Day") {
      Picker("Day", selection: $selectedDayOfYear) {
        ForEach(1...31, id: \.self) { day in
          Text("\(day)").tag(day)
        }
      }
    }
  }

  @ViewBuilder
  var deleteButton: some View {
    if existingOccurrence != nil, let onDelete {
      Button(role: .destructive) {
        onDelete()
        dismiss()
      } label: {
        Text("Delete")
      }
    }
  }

  var saveSection: some View {
    Button {
      saveOccurrence()
    } label: {
      Text(existingOccurrence == nil ? "Add" : "Update")
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
  }

  var isValid: Bool {
    switch cadenceType {
    case .daily:
      return true
    case .weekly:
      return !selectedWeekdays.isEmpty
    case .monthly:
      return selectedDayOfMonth >= 1 && selectedDayOfMonth <= 31
    case .yearly:
      return selectedMonth >= 1 && selectedMonth <= 12 && selectedDayOfYear >= 1 && selectedDayOfYear <= 31
    @unknown default:
      return false
    }
  }
  
  func saveOccurrence() {
    // Calculate time of day in seconds
    let calendar = Calendar.current
    let components = calendar.dateComponents([.hour, .minute], from: selectedTime)
    let hours = components.hour ?? 0
    let minutes = components.minute ?? 0
    let timeOfDay = TimeInterval(hours * 3600 + minutes * 60)

    let occurrence = ReminderOccurrence(
      cadenceType: cadenceType,
      timeOfDay: timeOfDay,
      daysOfWeek: cadenceType == .weekly ? Array(selectedWeekdays).sorted() : nil,
      dayOfMonth: cadenceType == .monthly ? selectedDayOfMonth : nil,
      monthOfYear: cadenceType == .yearly ? selectedMonth : nil,
      dayOfYear: cadenceType == .yearly ? selectedDayOfYear : nil
    )
    
    // Preserve the ID if editing
    if let existingOccurrence {
      occurrence.id = existingOccurrence.id
    }
    
    onSave(occurrence)
    dismiss()
  }
}

#Preview("New Occurrence") {
  PreviewSheetPresent {
    EditReminderOccurrenceView(occurrence: nil) { _ in }
  }
}

#Preview("Edit Daily") {
  PreviewSheetPresent {
    EditReminderOccurrenceView(
      occurrence: ReminderOccurrence(
        cadenceType: .daily,
        timeOfDay: 9 * 3600
      )
    ) { _ in
    } onDelete: {

    }
  }
}

#Preview("Edit Weekly") {
  PreviewSheetPresent {
    EditReminderOccurrenceView(
      occurrence: ReminderOccurrence(
        cadenceType: .weekly,
        timeOfDay: 14 * 3600,
        daysOfWeek: [2, 4, 6]
      )
    ) { _ in
    } onDelete: {

    }
  }
}

#Preview("Edit Monthly") {
  PreviewSheetPresent {
    EditReminderOccurrenceView(
      occurrence: ReminderOccurrence(
        cadenceType: .monthly,
        timeOfDay: 14 * 3600,
        dayOfMonth: 4
      )
    ) { _ in
    } onDelete: {

    }
  }
}

#Preview("Edit Yearly") {
  PreviewSheetPresent {
    EditReminderOccurrenceView(
      occurrence: ReminderOccurrence(
        cadenceType: .yearly,
        timeOfDay: 14 * 3600,
        monthOfYear: 5,
        dayOfYear: 11
      )
    ) { _ in
    } onDelete: {

    }
  }
}
