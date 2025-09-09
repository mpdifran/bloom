//
//  CalendarManager.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-25.
//

import Foundation
@preconcurrency import EventKit
import BloomFoundation

final class CalendarManager: Sendable {
    static let shared = CalendarManager()

    let eventStore = EKEventStore()

    private init() { }
}

extension CalendarManager {

    func promptForPermission() async {
        do {
            try await eventStore.requestFullAccessToEvents()
        } catch {
            print(error)
        }
    }
}

extension CalendarManager {

    func createEvent() -> EKEvent {
        EKEvent(eventStore: eventStore)
    }
}

extension CalendarManager {
    
    func getAllCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .event)
    }
    
    func getCalendars(with identifiers: Set<String>) -> [EKCalendar] {
        return getAllCalendars().filter { identifiers.contains($0.calendarIdentifier) }
    }
    
    @MainActor
    private func getFilteredCalendars() -> [EKCalendar]? {
        let selectedIdentifiers = CalendarPreferenceManager.shared.selectedCalendarIdentifiers
        if selectedIdentifiers.isEmpty {
            return nil // nil means all calendars
        }
        return getCalendars(with: selectedIdentifiers)
    }

    func eventsToday() async -> [EKEvent] {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return [] }

        let dateRange = DateRange.today()
        let calendars = await getFilteredCalendars()
        let predicate = eventStore.predicateForEvents(
            withStart: dateRange.start,
            end: dateRange.end,
            calendars: calendars
        )

        return await eventStore.fetchEvents(matching: predicate)
    }

    func eventsTomorrow() async -> [EKEvent] {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return [] }

        let dateRange = DateRange.tomorrow()
        let calendars = await getFilteredCalendars()
        let predicate = eventStore.predicateForEvents(
            withStart: dateRange.start,
            end: dateRange.end,
            calendars: calendars
        )

        return await eventStore.fetchEvents(matching: predicate)
    }
    
    func events(for dateRange: DateRange) async -> [EKEvent] {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return [] }
        
        let calendars = await getFilteredCalendars()
        let predicate = eventStore.predicateForEvents(
            withStart: dateRange.start,
            end: dateRange.end,
            calendars: calendars
        )
        
        return await eventStore.fetchEvents(matching: predicate)
    }
}
