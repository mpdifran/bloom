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
    case .today: return "Today"
    case .tomorrow: return "Tomorrow"
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

  var body: some View {
    VStack(spacing: 12) {
      if events.isEmpty {
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
    .animation(.default, value: events.count)
    .task {
      await CalendarManager.shared.promptForPermission()
      switch day {
      case .today:
        self.events = await CalendarManager.shared.eventsToday()
      case .tomorrow:
        self.events = await CalendarManager.shared.eventsTomorrow()
      }
    }
  }
}

private extension CalendarTodayCell {

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
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      CalendarTodayCell(day: .today)
    }
  }
}
