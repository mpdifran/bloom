//
//  CalendarManager.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-25.
//

import Foundation
@preconcurrency import EventKit
import BloomFoundation
import AppUI
import SwiftUI

@MainActor
final class CalendarManager: ObservableObject {
  static let shared = CalendarManager()

  private init() { }

  nonisolated(unsafe) let eventStore = EKEventStore()

  @Published var authStatus: EKAuthorizationStatus = .notDetermined
}

extension CalendarManager {

  func checkPermission() {
    self.authStatus = EKEventStore.authorizationStatus(for: .event)
  }

  func promptForPermission(alertDetails: Binding<AlertDetails?>) async {
    checkPermission()

    switch EKEventStore.authorizationStatus(for: .event) {
    case .notDetermined:
      do {
        try await eventStore.requestFullAccessToEvents()
        checkPermission()
      } catch {
        alertDetails.wrappedValue = AlertDetails(error: error)
      }
    case .denied:
      alertDetails.wrappedValue = permissionAlert
    case .restricted:
      alertDetails.wrappedValue = restrictionAlert
    case .fullAccess, .writeOnly:
      break
    @unknown default:
      break
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
    let calendars = getFilteredCalendars()
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
    let calendars = getFilteredCalendars()
    let predicate = eventStore.predicateForEvents(
      withStart: dateRange.start,
      end: dateRange.end,
      calendars: calendars
    )

    return await eventStore.fetchEvents(matching: predicate)
  }

  func events(for dateRange: DateRange) async -> [EKEvent] {
    guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return [] }

    let calendars = getFilteredCalendars()
    let predicate = eventStore.predicateForEvents(
      withStart: dateRange.start,
      end: dateRange.end,
      calendars: calendars
    )

    return await eventStore.fetchEvents(matching: predicate)
  }
}

private extension CalendarManager {

  var permissionAlert: AlertDetails {
    AlertDetails(
      title: "Calendar Access Denied",
      message: "Please allow calendar access in Settings.",
      buttons: [
        AlertDetails.Button(
          title: "Open Settings",
          action: { [weak self] in
            self?.openSettings()
          }
        ),
        AlertDetails.Button(
          title: "Cancel",
          role: .cancel
        ) { }
      ]
    )
  }

  var restrictionAlert: AlertDetails {
    AlertDetails(
      title: "Calendar Access Restricted",
      message: "Calendar access is restricted by Screen Time or parental controls. To enable access, have your parent or guardian allow Calendar access for this app in Screen Time settings.",
      buttons: [
        AlertDetails.Button(
          title: "OK",
          action: { }
        )
      ]
    )
  }

  func openSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
  }
}
