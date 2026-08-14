//
//  CalendarTodayCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-29.
//

import SwiftUI
@preconcurrency import EventKit
import EventKitUI
import AppUI

enum CalendarDay: CaseIterable {
  case today
  case tomorrow
  
  var displayName: String {
    switch self {
    case .today: return String(localized: "Today", comment: "Display name for calendar day")
    case .tomorrow: return String(localized: "Tomorrow", comment: "Display name for calendar day")
    }
  }
}

struct CalendarTodayCell: View {
  let day: CalendarDay
  
  init(day: CalendarDay) {
    self.day = day
  }

  @State private var events = [EKEvent]()
  @State private var selectedEvent: EKEvent?
  @State private var presentedSheet: AnyView?
  @State private var alertDetails: AlertDetails?

  @StateObject private var calendarManager = CalendarManager.shared

  var body: some View {
    VStack(spacing: 12) {
      if calendarManager.authStatus != .fullAccess {
        noPermissionView
      } else if events.isEmpty {
        noEventsView
      }

      ForEach(allDayEvents) { event in
        AllDayEventCell(event: event)
          .selectable()
          .onTapGesture {
            presentedSheet = EKEventView(event: event).asAny
          }
      }

      if allDayEvents.isNotEmpty && nonAllDayEvents.isNotEmpty {
        Divider()
      }

      ForEach(nonAllDayEvents) { event in
        EventCell(event: event)
          .selectable()
          .onTapGesture {
            presentedSheet = EKEventView(event: event).asAny
          }
      }
    }
    .cardContainer()
    .sheet($presentedSheet)
    .alert(alertDetails: $alertDetails)
    .animation(.default, value: events.count)
    .onAppear {
      calendarManager.checkPermission()

      Task {
        await loadEvents()
      }
    }
    .onChange(of: calendarManager.authStatus) { oldValue, newValue in
      guard newValue == .fullAccess else { return }

      Task {
        await loadEvents()
      }
    }
    .task {
      await loadEvents()
    }
  }
}

private extension CalendarTodayCell {

  func loadEvents() async {
    switch day {
    case .today:
      self.events = await CalendarManager.shared.eventsToday()
    case .tomorrow:
      self.events = await CalendarManager.shared.eventsTomorrow()
    }
  }

  var allDayEvents: [EKEvent] {
    events.filter({ $0.isAllDay })
  }

  var nonAllDayEvents: [EKEvent] {
    events.filter({ !$0.isAllDay })
  }

  var noEventsView: some View {
    ContentUnavailableView(
      "No Events",
      systemSymbol: .calendar,
      description: Text("You have no events \(day == .today ? "today" : "tomorrow").")
    )
    .fixedSize(horizontal: false, vertical: true)
    .foregroundStyle(.secondary)
    .horizontallyCentered()
//    .frame(height: 140)
  }

  var noPermissionView: some View {
    ContentUnavailableView {
      Label("Allow Calendar Access", systemSymbol: .calendarBadgeExclamationmark)
    } description: {
      Text("Allow access to your calendar to display events here.")
    } actions: {
      AsyncButton {
        await calendarManager.promptForPermission(alertDetails: $alertDetails)
      } label: {
        Text("Allow Access")
      }
      .buttonStyle(.tertiary)
    }
    .fixedSize(horizontal: false, vertical: true)
    .foregroundStyle(.secondary)
    .horizontallyCentered()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      CalendarTodayCell(day: .today)
    }
  }
}
