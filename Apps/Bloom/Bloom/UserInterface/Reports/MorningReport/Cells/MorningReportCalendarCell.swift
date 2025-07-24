//
//  MorningReportCalendarCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-24.
//

import SwiftUI
@preconcurrency import EventKit
import EventKitUI
import AppUI

struct MorningReportCalendarCell: View {

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
      self.events = await CalendarManager.shared.eventsToday()
    }
  }
}

private extension MorningReportCalendarCell {

  var allDayEvents: [EKEvent] {
    events.filter({ $0.isAllDay })
  }

  var nonAllDayEvents: [EKEvent] {
    events.filter({ !$0.isAllDay })
  }

  var noEventsView: some View {
    Text("No Events")
      .font(.title3)
      .bold()
      .foregroundStyle(.secondary)
      .horizontallyCentered()
      .frame(height: 100)
  }
}

#Preview {
  MorningReportCalendarCell()
}
