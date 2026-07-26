//
//  CalendarSelectionView.swift
//  Bloom
//
//  Created by Assistant on 2025-09-09.
//

import SwiftUI
import AppUI
@preconcurrency import EventKit

struct CalendarSelectionView: View {
  @State private var calendarPreferences = CalendarPreferenceManager.shared
  @State private var calendars: [EKCalendar] = []
  @State private var alertDetails: AlertDetails?

  @StateObject private var calendarManager = CalendarManager.shared

  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    BloomScrollView {
      if calendarManager.authStatus != .fullAccess {
        noPermissionView
      } else if calendars.isEmpty {
        noCalendarsView
      } else {
        calendarSection
      }
    }
    .navigationTitle("Calendars")
    .navigationBarTitleDisplayMode(.inline)
    .alert(alertDetails: $alertDetails)
    .onAppear {
      calendarManager.checkPermission()
      guard calendarManager.authStatus == .fullAccess else { return }

      loadCalendars()
    }
    .onChange(of: calendarManager.authStatus) { oldValue, newValue in
      guard newValue == .fullAccess else { return }

      loadCalendars()
    }
  }
}

private extension CalendarSelectionView {
  
  @ViewBuilder
  var calendarSection: some View {
    VStack {
      HStack(alignment: .firstTextBaseline) {
        SectionTitleView("Select Calendars")
        
        Spacer()
        
        Button(selectAllButtonTitle) {
          toggleAllCalendars()
        }
        .font(.footnote)
        .bold()
        .frame(height: 35)
      }
      .padding(.horizontal)
      
      SettingsSectionContainer {
        ForEach(Array(calendars.enumerated()), id: \.element.calendarIdentifier) { index, calendar in
          if index > 0 {
            Divider()
          }
          
          CalendarSelectionCell(
            calendar: calendar,
            isSelected: calendarPreferences.selectedCalendarIdentifiers.contains(calendar.calendarIdentifier)
          ) { isSelected in
            toggleCalendar(calendar, isSelected: isSelected)
          }
        }
      }
    }
  }

  var noCalendarsView: some View {
    ContentUnavailableView(
      "No Calendars",
      systemSymbol: .calendar,
      description: Text("You have no calendars.")
    )
    .padding()
    .fixedSize(horizontal: false, vertical: true)
    .foregroundStyle(.secondary)
    .horizontallyCentered()
  }

  var noPermissionView: some View {
    ContentUnavailableView {
      Label("Allow Calendar Access", systemSymbol: .calendarBadgeExclamationmark)
    } description: {
      Text("Allow access in order to filter your calendars here.")
    } actions: {
      AsyncButton {
        await calendarManager.promptForPermission(alertDetails: $alertDetails)
      } label: {
        Text("Allow Access")
      }
      .buttonStyle(.tertiary)
    }
    .padding()
    .fixedSize(horizontal: false, vertical: true)
    .foregroundStyle(.secondary)
    .horizontallyCentered()
  }
  
  var selectAllButtonTitle: String {
    if calendarPreferences.selectedCalendarIdentifiers.isEmpty || 
       calendarPreferences.selectedCalendarIdentifiers.count == calendars.count {
      return "Deselect All"
    } else {
      return "Select All"
    }
  }
  
  func loadCalendars() {
    calendars = CalendarManager.shared.getAllCalendars()
    
    // If no calendars are selected yet (first time), select all
    if calendarPreferences.selectedCalendarIdentifiers.isEmpty {
      calendarPreferences.selectedCalendarIdentifiers = Set(calendars.map { $0.calendarIdentifier })
    }
  }
  
  func toggleCalendar(_ calendar: EKCalendar, isSelected: Bool) {
    if isSelected {
      calendarPreferences.selectedCalendarIdentifiers.insert(calendar.calendarIdentifier)
    } else {
      calendarPreferences.selectedCalendarIdentifiers.remove(calendar.calendarIdentifier)
    }
  }
  
  func toggleAllCalendars() {
    if calendarPreferences.selectedCalendarIdentifiers.isEmpty || 
       calendarPreferences.selectedCalendarIdentifiers.count == calendars.count {
      // Deselect all
      calendarPreferences.selectedCalendarIdentifiers = []
    } else {
      // Select all
      calendarPreferences.selectedCalendarIdentifiers = Set(calendars.map { $0.calendarIdentifier })
    }
  }
}

struct CalendarSelectionCell: View {
  let calendar: EKCalendar
  let isSelected: Bool
  let onToggle: (Bool) -> Void
  
  var body: some View {
    HStack {
      Circle()
        .fill(Color(cgColor: calendar.cgColor))
        .frame(width: 10, height: 10)

      Text(calendar.title)
        .bold()
        .fontDesign(.rounded)
        .minimumScaleFactor(0.7)
        .lineLimit(2)
        .layoutPriority(10)

      Spacer()

      Toggle("", isOn: Binding(
        get: { isSelected },
        set: { onToggle($0) }
      ))
      .tint(.mutedGreen)
    }
    .frame(minHeight: 60)
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      CalendarSelectionView()
    }
  }
}
