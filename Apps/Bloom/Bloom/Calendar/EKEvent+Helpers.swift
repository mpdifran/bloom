//
//  EKEvent+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-25.
//

import SwiftUI
@preconcurrency import EventKit

extension EKEvent: @retroactive Identifiable {
  public var id: String { eventIdentifier }
}

extension EKEvent {

  var duration: TimeInterval {
    endDate.timeIntervalSince(startDate)
  }

  var isStartingSoon: Bool {
    startDate.timeIntervalSinceNow > 0 && startDate.timeIntervalSinceNow < 1800
  }

  var hasStarted: Bool {
    startDate.timeIntervalSinceNow < 0 && endDate.timeIntervalSinceNow >= 0
  }

  var hasCompleted: Bool {
    endDate.timeIntervalSinceNow < 0
  }
}

@MainActor
extension EKEvent {
  static let preview = CalendarManager.shared.createEvent().with {
    let calendar = EKCalendar(for: .event, eventStore: CalendarManager.shared.eventStore)
    $0.title = "Preview Event"
    $0.availability = .busy
    $0.startDate = Date.now.addingTimeInterval(-3600)
    $0.endDate = Date.now
    $0.calendar = calendar

    try? CalendarManager.shared.eventStore.saveCalendar(calendar, commit: false)
    try? CalendarManager.shared.eventStore.save($0, span: .thisEvent)
    try? CalendarManager.shared.eventStore.commit()
  }

  static let futurePreview = CalendarManager.shared.createEvent().with {
    let calendar = EKCalendar(for: .event, eventStore: CalendarManager.shared.eventStore)
    calendar.cgColor = UIColor(red: 1, green: 0, blue: 0.5, alpha: 1).cgColor

    $0.title = "Future Preview Event"
    $0.availability = .busy
    $0.startDate = Date.now.addingTimeInterval(1600)
    $0.endDate = Date.now.addingTimeInterval(5200)
    $0.calendar = calendar
    $0.structuredLocation = EKStructuredLocation(title: "Home")

    try? CalendarManager.shared.eventStore.saveCalendar(calendar, commit: false)
    try? CalendarManager.shared.eventStore.save($0, span: .thisEvent)
    try? CalendarManager.shared.eventStore.commit()
  }

  static let allDayPreview = CalendarManager.shared.createEvent().with {
    let calendar = EKCalendar(for: .event, eventStore: CalendarManager.shared.eventStore)
    $0.title = "All Day Event"
    $0.availability = .busy
    $0.startDate = Date.now
    $0.isAllDay = true
    $0.calendar = calendar

    try? CalendarManager.shared.eventStore.saveCalendar(calendar, commit: false)
    try? CalendarManager.shared.eventStore.save($0, span: .thisEvent)
    try? CalendarManager.shared.eventStore.commit()
  }
}
