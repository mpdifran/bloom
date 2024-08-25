//
//  EKEventStore+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-25.
//

import Foundation
import EventKit

extension EKEventStore {

    func fetchEvents(matching predicate: NSPredicate) async -> [EKEvent] {
        await withCheckedContinuation { continuation in
            var events = [EKEvent]()
            enumerateEvents(matching: predicate) { event, pointer in
                events.append(event)
            }
            continuation.resume(returning: events)
        }
    }
}
