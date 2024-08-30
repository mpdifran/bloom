//
//  EKEvent+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-25.
//

import SwiftUI
import EventKit

extension EKEvent: Identifiable {
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

extension EKEvent {
    static var preview = {
        let event = EKEvent.init(eventStore: CalendarManager.shared.eventStore)

        event.title = "Preview Event"
        event.availability = .busy
        event.startDate = Date.now.addingTimeInterval(-3600)
        event.endDate = Date.now
        event.calendar = CalendarManager.shared.eventStore.defaultCalendarForNewEvents

        try? CalendarManager.shared.eventStore.save(event, span: .thisEvent)
        try? CalendarManager.shared.eventStore.commit()

        return event
    }()

    static var futurePreview = {
        let event = EKEvent.init(eventStore: CalendarManager.shared.eventStore)

        let calendar = EKCalendar(for: .event, eventStore: CalendarManager.shared.eventStore)
        calendar.cgColor = UIColor(red: 1, green: 0, blue: 0.5, alpha: 1).cgColor

        event.title = "Future Preview Event"
        event.availability = .busy
        event.startDate = Date.now.addingTimeInterval(1600)
        event.endDate = Date.now.addingTimeInterval(5200)
        event.calendar = calendar
        event.structuredLocation = .init(title: "Home")

        try? CalendarManager.shared.eventStore.saveCalendar(calendar, commit: false)
        try? CalendarManager.shared.eventStore.save(event, span: .thisEvent)
        try? CalendarManager.shared.eventStore.commit()

        return event
    }()

    static var allDayPreview = {
        let event = EKEvent.init(eventStore: CalendarManager.shared.eventStore)

        event.title = "All Day Event"
        event.availability = .busy
        event.startDate = Date.now
        event.endDate = Date.now.addingTimeInterval(3600 * 24)
        event.isAllDay = true
        event.calendar = CalendarManager.shared.eventStore.defaultCalendarForNewEvents

        try? CalendarManager.shared.eventStore.save(event, span: .thisEvent)
        try? CalendarManager.shared.eventStore.commit()

        return event
    }()
}
