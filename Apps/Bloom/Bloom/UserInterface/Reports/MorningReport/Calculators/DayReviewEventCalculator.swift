//
//  DayReviewEventCalculator.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-23.
//

import Foundation
@preconcurrency import EventKit
import BloomFoundation

final actor DayReviewEventCalculator {
  static let shared = DayReviewEventCalculator()

  private init() { }
}

extension DayReviewEventCalculator {

  func calculateEventDataString(for date: Date) async throws -> String {
    let eventData = await calculateEventData(for: date)
    let jsonData = try JSONEncoder.bloomModel.encode(eventData)
    return String(data: jsonData, encoding: .utf8) ?? "{}"
  }

  func calculateEventData(for date: Date) async -> DayReviewEventData? {
    guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
      return nil
    }

    let calendarManager = CalendarManager.shared

    async let yesterdayEvents = fetchYesterdayEvents(calendarManager: calendarManager)
    async let todayEvents = fetchTodayEvents(calendarManager: calendarManager)

    let (yesterday, today) = await (yesterdayEvents, todayEvents)

    return DayReviewEventData(
      yesterdayEvents: yesterday.map { convertToCalendarEvent($0) },
      todayEvents: today.map { convertToCalendarEvent($0) }
    )
  }
}

private extension DayReviewEventCalculator {

  func fetchYesterdayEvents(calendarManager: CalendarManager) async -> [EKEvent] {
    let dateRange = DateRange.yesterday()
    let predicate = calendarManager.eventStore.predicateForEvents(
      withStart: dateRange.start,
      end: dateRange.end,
      calendars: nil
    )

    return await calendarManager.eventStore.fetchEvents(matching: predicate)
  }

  func fetchTodayEvents(calendarManager: CalendarManager) async -> [EKEvent] {
    return await calendarManager.eventsToday()
  }

  func convertToCalendarEvent(_ ekEvent: EKEvent) -> CalendarEvent {
    return CalendarEvent(
      id: ekEvent.eventIdentifier ?? UUID().uuidString,
      title: ekEvent.title ?? "",
      startDate: ekEvent.startDate,
      endDate: ekEvent.endDate,
      isAllDay: ekEvent.isAllDay,
      location: ekEvent.location,
      notes: ekEvent.notes
    )
  }
}
