//
//  DayReviewEventData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-23.
//

import Foundation
import CoreNetwork

struct DayReviewEventData: SendableNetworkModel {
  let yesterdayEvents: [CalendarEvent]
  let todayEvents: [CalendarEvent]
}

struct CalendarEvent: SendableNetworkModel {
  let id: String
  let title: String
  let startDate: Date
  let endDate: Date
  let isAllDay: Bool
  let location: String?
  let notes: String?
}