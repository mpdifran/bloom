//
//  MorningReportSettingsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-26.
//

import SwiftUI
import AppUI
@preconcurrency import EventKit

struct MorningReportSettingsView: View {
  @Bindable private var reportViewModel = ReportCoordinatorViewModel.shared
  @State private var calendars: [EKCalendar] = []
  @State private var hasCalendarPermission = false

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      BloomScrollView {
        notificationSection
        calendarSection
      }
      .navigationTitle("Morning Report")
      .navigationBarTitleDisplayMode(.inline)
      .presentationDragIndicator(.visible)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") {
            dismiss()
          }
          .bold()
        }
      }
    }
    .task {
      await checkCalendarPermission()
      loadCalendars()
    }
  }
}

private extension MorningReportSettingsView {
  
  var notificationSection: some View {
    VStack {
      SectionTitleView("Notifications")
        .padding(.horizontal)
        
      SettingsSectionContainer {
        SettingsCell("Send Report on Wake Up") {
          Toggle("", isOn: $reportViewModel.showMorningReportOnWakeUp)
            .tint(.mutedGreen)
        }
        
//        Divider()
//        
//        SettingsCell("Send Report By") {
//          DatePicker("", selection: $reportViewModel.morningReportDate, displayedComponents: .hourAndMinute)
//            .datePickerStyle(.compact)
//        }
      }
    }
  }
  
  @ViewBuilder
  var calendarSection: some View {
    if hasCalendarPermission && calendars.isNotEmpty {
      VStack {
        HStack {
          SectionTitleView("Calendars")
          
          Spacer()
          
          Button(selectAllButtonTitle) {
            toggleAllCalendars()
          }
          .font(.footnote)
          .bold()
        }
        .padding(.horizontal)
        
        SettingsSectionContainer {
          ForEach(Array(calendars.enumerated()), id: \.element.calendarIdentifier) { index, calendar in
            if index > 0 {
              Divider()
            }
            
            CalendarSelectionCell(
              calendar: calendar,
              isSelected: reportViewModel.selectedCalendarIdentifiers.contains(calendar.calendarIdentifier)
            ) { isSelected in
              toggleCalendar(calendar, isSelected: isSelected)
            }
          }
        }
      }
    }
  }
  
  var selectAllButtonTitle: String {
    if reportViewModel.selectedCalendarIdentifiers.isEmpty || 
       reportViewModel.selectedCalendarIdentifiers.count == calendars.count {
      return "Deselect All"
    } else {
      return "Select All"
    }
  }
  
  func checkCalendarPermission() async {
    hasCalendarPermission = EKEventStore.authorizationStatus(for: .event) == .fullAccess
  }
  
  func loadCalendars() {
    calendars = CalendarManager.shared.getAllCalendars()
    
    // If no calendars are selected yet (first time), select all
    if reportViewModel.selectedCalendarIdentifiers.isEmpty {
      reportViewModel.selectedCalendarIdentifiers = Set(calendars.map { $0.calendarIdentifier })
    }
  }
  
  func toggleCalendar(_ calendar: EKCalendar, isSelected: Bool) {
    if isSelected {
      reportViewModel.selectedCalendarIdentifiers.insert(calendar.calendarIdentifier)
    } else {
      reportViewModel.selectedCalendarIdentifiers.remove(calendar.calendarIdentifier)
    }
  }
  
  func toggleAllCalendars() {
    if reportViewModel.selectedCalendarIdentifiers.isEmpty || 
       reportViewModel.selectedCalendarIdentifiers.count == calendars.count {
      // Deselect all
      reportViewModel.selectedCalendarIdentifiers = []
    } else {
      // Select all
      reportViewModel.selectedCalendarIdentifiers = Set(calendars.map { $0.calendarIdentifier })
    }
  }
}

struct CalendarSelectionCell: View {
  let calendar: EKCalendar
  let isSelected: Bool
  let onToggle: (Bool) -> Void
  
  var body: some View {
    SettingsCell(calendar.title) {
      HStack(spacing: 12) {
        Circle()
          .fill(Color(cgColor: calendar.cgColor))
          .frame(width: 10, height: 10)
        
        Toggle("", isOn: Binding(
          get: { isSelected },
          set: { onToggle($0) }
        ))
        .tint(.mutedGreen)
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    MorningReportSettingsView()
  }
}
