//
//  TimeConfigurationCell.swift
//  Bloom
//
//  Created by Assistant on 2025-08-27.
//

import SwiftUI
import BloomUI
import SFSafeSymbols

struct TimeConfigurationCell: View {
  let timeMode: TimeMode
  let startHour: Int
  let startMinute: Int
  let todaySettings: TodaySettings
  let onTimeChanged: (Int, Int) -> Void

  @State private var showingTimePicker = false

  private var timeFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
  }

  private var startTime: Date {
    let calendar = Calendar.current
    let components = DateComponents(hour: startHour, minute: startMinute)
    return calendar.date(from: components) ?? Date()
  }

  private var endTime: Date {
    let calendar = Calendar.current
    let endHour = getEndHour()
    let endMinute = getEndMinute()
    let components = DateComponents(hour: endHour, minute: endMinute)
    return calendar.date(from: components) ?? Date()
  }

  private func getEndHour() -> Int {
    switch timeMode {
    case .morning:
      return todaySettings.afternoonStartHour
    case .afternoon:
      return todaySettings.eveningStartHour
    case .evening:
      return todaySettings.nightStartHour
    case .night:
      return todaySettings.morningStartHour
    @unknown default:
      return todaySettings.morningStartHour
    }
  }

  private func getEndMinute() -> Int {
    switch timeMode {
    case .morning:
      return todaySettings.afternoonStartMinute
    case .afternoon:
      return todaySettings.eveningStartMinute
    case .evening:
      return todaySettings.nightStartMinute
    case .night:
      return todaySettings.morningStartMinute
    @unknown default:
      return todaySettings.morningStartMinute
    }
  }
  
  private var timeRangeText: String {
    let startString = timeFormatter.string(from: startTime)
    let endString = timeFormatter.string(from: endTime)
    
    // Check if this mode spans midnight (only night mode typically does this)
    let spansNextDay = timeMode == .night && startHour > getEndHour()
    
    if spansNextDay {
      return "\(startString) - \(endString) +1 day"
    } else {
      return "\(startString) - \(endString)"
    }
  }
  
  var body: some View {
    HStack {
      Image(systemSymbol: timeMode.icon)
        .font(.body)
        .foregroundStyle(.white)
        .frame(width: 24)
        .padding(6)
        .background {
          RoundedRectangle(cornerRadius: 10)
            .fill(timeMode.tintColor)
        }

      VStack(alignment: .leading, spacing: 2) {
        Text(timeMode.displayName)
          .bold()
          .fontDesign(.rounded)
        
        Text(timeRangeText)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      
      Spacer()
      
      Button {
        showingTimePicker = true
      } label: {
        Text(timeFormatter.string(from: startTime))
          .foregroundStyle(timeMode.tintColor)
          .bold()
          .fontDesign(.rounded)
      }
    }
    .frame(minHeight: 60)
    .selectable()
    .sheet(isPresented: $showingTimePicker) {
      TimePickerSheet(
        timeMode: timeMode,
        selectedHour: startHour,
        selectedMinute: startMinute,
        onSave: { hour, minute in
          onTimeChanged(hour, minute)
          showingTimePicker = false
        }
      )
      .tint(timeMode.tintColor)
    }
  }
}

private struct TimePickerSheet: View {
  let timeMode: TimeMode
  let selectedHour: Int
  let selectedMinute: Int
  let onSave: (Int, Int) -> Void

  @State private var selectedTime: Date
  @Environment(\.dismiss) private var dismiss

  init(timeMode: TimeMode, selectedHour: Int, selectedMinute: Int, onSave: @escaping (Int, Int) -> Void) {
    self.timeMode = timeMode
    self.selectedHour = selectedHour
    self.selectedMinute = selectedMinute
    self.onSave = onSave

    let calendar = Calendar.current
    let components = DateComponents(hour: selectedHour, minute: selectedMinute)
    self._selectedTime = State(initialValue: calendar.date(from: components) ?? Date())
  }
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 20) {
        VStack(spacing: 8) {
          Image(systemSymbol: timeMode.icon)
            .font(.largeTitle)
            .foregroundStyle(.tint)
          
          Text("Set \(timeMode.displayName) Start Time")
            .font(.title2)
            .bold()
            .fontDesign(.rounded)
        }
        .padding(.top, 20)
        
        DatePicker(
          "",
          selection: $selectedTime,
          displayedComponents: .hourAndMinute
        )
        .datePickerStyle(.wheel)
        .labelsHidden()
        
        Spacer()
      }
      .padding()
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
        
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            let hour = Calendar.current.component(.hour, from: selectedTime)
            let minute = Calendar.current.component(.minute, from: selectedTime)
            onSave(hour, minute)
            dismiss()
          }
          .bold()
        }
      }
    }
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
  }
}
