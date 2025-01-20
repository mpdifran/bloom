//
//  EKEventStore+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-25.
//

import Foundation
@preconcurrency import EventKit

extension EKEventStore {

    func fetchEvents(matching predicate: NSPredicate) async -> [EKEvent] {
        await withCheckedContinuation { continuation in
//            var events = [EKEvent]()
//            enumerateEvents(matching: predicate) { event, pointer in
//                events.append(event)
//            }
            let events: [EKEvent] = {
                var collectedEvents = [EKEvent]()
                enumerateEvents(matching: predicate) { event, _ in
                    collectedEvents.append(event)
                }
                return collectedEvents
            }()

            continuation.resume(returning: events)
        }
    }
}
