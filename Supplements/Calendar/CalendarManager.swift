//
//  CalendarManager.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-25.
//

import Foundation
import EventKit
import BloomFoundation

final actor CalendarManager {
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

    func eventsToday() async -> [EKEvent] {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return [] }

        let dateRange = DateRange.today()
        let predicate = eventStore.predicateForEvents(
            withStart: dateRange.start,
            end: dateRange.end,
            calendars: nil
        )

        return await eventStore.fetchEvents(matching: predicate)
    }

    func eventsTomorrow() async -> [EKEvent] {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return [] }

        let dateRange = DateRange.tomorrow()
        let predicate = eventStore.predicateForEvents(
            withStart: dateRange.start,
            end: dateRange.end,
            calendars: nil
        )

        return await eventStore.fetchEvents(matching: predicate)
    }
}
